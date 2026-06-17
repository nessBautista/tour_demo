//
//  DevTools.swift
//  tourDemoApp — App/DevTools
//
//  A global, DEBUG-only developer overlay. Installed once at the app root via
//  `.devTools()`, toggled by SHAKING the device (Simulator → Device → Shake, or
//  ⌃⌘Z). Because the trigger lives on the window, every screen gets it with no
//  per-screen code. Entirely stripped from release builds.
//
//  This replaces a navigation/tab entry point — the developer surface is reached
//  only by the shake gesture.
//

import SwiftUI
import UIKit

// MARK: - Public logging API (compiled in ALL configs; no-op in release)

enum DevLogLevel: String, CaseIterable {
    case debug, info, warn, error
}

/// Lightweight debug logging that surfaces in the Developer Tools "Logs" panel
/// (DEBUG only). Safe to call from anywhere — a no-op in release builds.
func devLog(_ message: @autoclosure () -> String, level: DevLogLevel = .info) {
    #if DEBUG
    let text = message()
    DevLog.shared.log(text, level: level)
    // Also emit to the Xcode console so a full session trace can be copy-pasted.
    // Greppable prefix `TD|` and the level; e.g. `TD|warn| memory: ⚠ contradiction …`.
    print("TD|\(level.rawValue)| \(text)")
    #endif
}

// MARK: - Entry-point modifier (compiled in ALL configs)

extension View {
    /// Installs the global Developer Tools overlay (shake to toggle). No-op in release.
    func devTools() -> some View {
        #if DEBUG
        return modifier(DevToolsContainer())
        #else
        return self
        #endif
    }
}

#if DEBUG

// MARK: - Shared state

@Observable
final class DevTools {
    static let shared = DevTools()
    var isPresented = false

    /// Demo control wired by the app root (e.g. RootView) — restarts onboarding.
    /// Optional so the panel only shows it once a host registers it.
    var onResetDemo: (() -> Void)?

    private init() {}
}

@Observable
final class DevLog {
    static let shared = DevLog()

    struct Entry: Identifiable {
        let id = UUID()
        let date: Date
        let level: DevLogLevel
        let message: String
    }

    private(set) var entries: [Entry] = []
    private let limit = 500

    private init() {}

    func log(_ message: String, level: DevLogLevel) {
        entries.insert(Entry(date: Date(), level: level, message: message), at: 0)
        if entries.count > limit { entries.removeLast(entries.count - limit) }
    }

    func clear() { entries.removeAll() }
}

// MARK: - Shake detection (global, via the window's motion responder)

extension Notification.Name {
    static let deviceDidShake = Notification.Name("TourDemo.deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

// MARK: - Overlay installer

private struct DevToolsContainer: ViewModifier {
    @State private var dev = DevTools.shared

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    dev.isPresented.toggle()
                }
            }
            .overlay {
                if dev.isPresented {
                    DevToolsPanel(dev: dev)
                        .transition(.opacity)
                }
            }
    }
}

#endif
