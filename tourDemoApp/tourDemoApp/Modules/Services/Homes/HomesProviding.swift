//
//  HomesProviding.swift
//  tourDemoApp — Modules/Services/Homes
//
//  The data-access seam for listings. Declared in the Services tier (below
//  Features), so the Today ViewModel depends on this protocol — never on URLSession
//  or a Supabase client directly (iOS architecture §2 / §3.1). Live and fixture
//  conformances are interchangeable, which is what makes the screen testable and
//  keyless-runnable.
//

import Foundation

protocol HomesProviding: Sendable {
    /// All listings, newest first.
    func fetchHomes() async throws -> [Home]
}
