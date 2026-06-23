//
//  CachedAsyncImage.swift
//  tourDemoApp — UI/Components
//
//  A drop-in replacement for SwiftUI's `AsyncImage` that keeps decoded images in a
//  shared in-memory cache. Two problems it solves over plain `AsyncImage`:
//
//   1. `AsyncImage` re-fetches from `.empty` on every reappearance — so Today →
//      Compare → Today flashes the placeholder while it reloads.
//   2. A naive cache that downloads inside the view's own `.task` loses the download
//      when the view disappears: SwiftUI CANCELS `.task` on disappear, so navigating
//      away mid-download (book tour → debrief → Compare) cancels the fetch *before*
//      it can be cached — and the image is never stored, so the next visit re-fetches.
//
//  Fix: the download runs in a shared, view-INDEPENDENT loader (`ImageCache`) as an
//  unstructured Task that is not a child of any view's `.task`. It therefore runs to
//  completion and caches the image even if the requesting view went away. The view
//  seeds its phase from the cache in `init` (a hit paints on the first frame — no
//  flash) and otherwise awaits the loader. The cache is a plain dictionary (never
//  evicts — we only have a handful of listing photos), so nothing is dropped under
//  the memory pressure of a screen recording.
//
//  Same phase-based API as `AsyncImage` (.empty / .success / .failure), so call sites
//  swap one type name and keep their existing `switch phase` body.
//

import SwiftUI
import UIKit

/// Process-wide image cache + loader. Downloads survive the requesting view's
/// cancellation; concurrent requests for the same URL are de-duped.
final class ImageCache {
    static let shared = ImageCache()

    private let lock = NSLock()
    private var cache: [URL: UIImage] = [:]
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    /// Synchronous peek — safe to call from a SwiftUI `View.init` (main thread).
    func cached(_ url: URL) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        return cache[url]
    }

    /// Returns the cached image, or downloads it. The download is an unstructured
    /// Task owned by the cache — cancelling the *caller* does not cancel it, so the
    /// image still lands in the cache for the next view that needs it.
    func image(for url: URL) async throws -> UIImage {
        if let img = cached(url) { return img }

        lock.lock()
        if let existing = inFlight[url] {
            lock.unlock()
            return try await existing.value
        }
        let task = Task<UIImage, Error> {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let img = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            self.store(img, for: url)   // cache write happens INSIDE the task
            return img
        }
        inFlight[url] = task
        lock.unlock()
        return try await task.value
    }

    private func store(_ image: UIImage, for url: URL) {
        lock.lock(); cache[url] = image; inFlight[url] = nil; lock.unlock()
    }

    /// Warm the cache ahead of display (e.g. when the homes list loads) so photos are
    /// already resident before the user navigates. Fire-and-forget.
    func prefetch(_ urls: [URL]) {
        for url in urls where cached(url) == nil {
            Task { _ = try? await image(for: url) }
        }
    }
}

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    @ViewBuilder private let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
        // Seed from cache in init so a hit paints the image on the first frame (no flash).
        if let url, let cached = ImageCache.shared.cached(url) {
            _phase = State(initialValue: .success(Image(uiImage: cached)))
        } else {
            _phase = State(initialValue: .empty)
        }
    }

    var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { phase = .empty; return }
        if let cached = ImageCache.shared.cached(url) {
            phase = .success(Image(uiImage: cached))
            return
        }
        do {
            let image = try await ImageCache.shared.image(for: url)
            phase = .success(Image(uiImage: image))
        } catch is CancellationError {
            // We navigated away; the shared loader keeps downloading and will cache it.
            // Don't downgrade to .failure — the next appearance seeds from cache.
        } catch {
            // A late cache hit (a sibling finished the download) still wins.
            if let cached = ImageCache.shared.cached(url) {
                phase = .success(Image(uiImage: cached))
            } else {
                phase = .failure(error)
            }
        }
    }
}
