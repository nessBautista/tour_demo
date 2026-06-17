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
        }
    }
}
