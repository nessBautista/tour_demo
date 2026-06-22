//
//  CachedAsyncImage.swift
//  tourDemoApp — UI/Components
//
//  A drop-in replacement for SwiftUI's `AsyncImage` that keeps decoded images in a
//  shared in-memory cache. `AsyncImage` re-fetches from `.empty` every time a view
//  reappears — so switching tabs (Today → Compare → Today) tears down the LazyVStack
//  rows and the listing photos flash back to the placeholder. Caching by URL makes a
//  re-appearance an instant cache hit: no refetch, no placeholder flash.
//
//  Same phase-based API as `AsyncImage` (.empty / .success / .failure) so call sites
//  swap one type name and keep their existing `switch phase` body.
//

import SwiftUI
import UIKit

/// Process-wide image cache. `NSCache` is thread-safe and evicts under memory pressure.
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? { cache.object(forKey: url as NSURL) }
    func insert(_ image: UIImage, for url: URL) { cache.setObject(image, forKey: url as NSURL) }
}

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    @ViewBuilder private let content: (AsyncImagePhase) -> Content
    @State private var phase: AsyncImagePhase

    init(url: URL?, @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
        // Seed from cache in init so a hit paints the image on the first frame (no flash).
        if let url, let cached = ImageCache.shared.image(for: url) {
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

        // Cache hit — already seeded in init, or seeded by a sibling since. Done.
        if let cached = ImageCache.shared.image(for: url) {
            phase = .success(Image(uiImage: cached))
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                phase = .failure(URLError(.cannotDecodeContentData))
                return
            }
            ImageCache.shared.insert(image, for: url)
            phase = .success(Image(uiImage: image))
        } catch {
            phase = .failure(error)
        }
    }
}
