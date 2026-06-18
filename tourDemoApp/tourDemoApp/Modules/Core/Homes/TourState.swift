//
//  TourState.swift
//  tourDemoApp — Modules/Core/Homes
//
//  Where a home sits in the tour funnel — the per-buyer ladder that gates the
//  debrief and decides who enters Compare:
//
//    notToured → booked → debriefed
//
//  A home is "toured" (eligible for Compare) once it's booked. `debriefed` is set
//  when at least one impression is recorded. State is per-buyer-session memory
//  (BuyerMemoryStore), not a property of the listing. Core tier: no UI, no copy —
//  the Today view maps each case to a badge + colour.
//

enum TourState: Equatable, Sendable, CaseIterable {
    case notToured
    case booked
    case debriefed

    /// Booked or debriefed — eligible to enter Compare.
    var isToured: Bool { self != .notToured }

    /// Funnel order, for advancing/seeding.
    var rank: Int {
        switch self {
        case .notToured: 0
        case .booked:    1
        case .debriefed: 2
        }
    }
}
