//
//  FixtureHomesService.swift
//  tourDemoApp — Modules/Services/Homes
//
//  The keyless path: a handful of canned listings so the app shows something with
//  no Supabase keys set (iOS architecture §6 — missing keys → fixtures). Doubles as
//  the deterministic data source for ViewModel tests. Fictional data, no real MLS.
//

import Foundation

struct FixtureHomesService: HomesProviding {
    var homes: [Home] = FixtureHomesService.demoHomes

    func fetchHomes() async throws -> [Home] { homes }

    static let demoHomes: [Home] = [
        Home(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!,
             address: "412 Alder Court, Maple Grove",
             price: 485_000, beds: 3, baths: 2,
             sqft: 1_840,
             headline: "Sun-drenched corner lot with a big yard",
             imageURL: nil),
        Home(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!,
             address: "88 Foundry Lane #4B, Riverside District",
             price: 529_000, beds: 2, baths: 2,
             sqft: 1_420,
             headline: "Modern loft, 12 minutes from downtown",
             imageURL: nil),
        Home(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000C3")!,
             address: "1735 Bellview Avenue, Old Town",
             price: 449_000, beds: 4, baths: 1.5,
             sqft: 1_820,
             headline: "Character craftsman on a quiet street; kitchen needs love",
             imageURL: nil),
    ]
}
