//
//  TourState.swift
//  tourDemoApp — Modules/Core/Homes
//
//  Where a home sits in the tour funnel. This feature (feat/per-home-debrief)
//  needs only the binary "have we toured it yet?" — a toured home unlocks the
//  voice debrief. The fuller ladder (notToured → booked → debriefed) is
//  feat/tour-state (a later PR); kept minimal here on purpose (disposable Lane-1).
//

enum TourState: Equatable, Sendable {
    case notToured
    case toured

    var isToured: Bool { self == .toured }
}
