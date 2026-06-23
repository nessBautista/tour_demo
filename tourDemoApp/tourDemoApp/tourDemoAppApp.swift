//
//  tourDemoAppApp.swift
//  tourDemoApp
//
//  Created by Ness on 17/06/26.
//

import SwiftUI

@main
struct tourDemoAppApp: App {
    /// The single container, assembled once at launch (iOS architecture §6).
    @State private var container = AppDependencyContainer()

    var body: some Scene {
        WindowGroup {
            container.makeRootView()
                .devTools() // global DEBUG overlay — shake (⌃⌘Z) to toggle
                // The design system is a fixed LIGHT palette (cold off-white surfaces +
                // dark text tokens). System-colored elements — nav large titles, default
                // Text, SF Symbols — would otherwise flip to white in Dark Mode while our
                // light surfaces stay, so the titles read white-on-light. Lock to light.
                .preferredColorScheme(.light)
        }
    }
}
