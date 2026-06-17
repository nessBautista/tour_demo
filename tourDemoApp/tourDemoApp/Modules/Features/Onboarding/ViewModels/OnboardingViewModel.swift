//
//  OnboardingViewModel.swift
//  tourDemoApp — Modules/Features/Onboarding/ViewModels
//
//  State-Driven MVVM for onboarding (iOS architecture §1/§4/§5). Drives the phase
//  machine and runs the extraction effect: a transcript → the extraction engine
//  (fixture now; the agent loop in Phase 3) → confirmation cards the buyer toggles
//  → "save". The buyer confirms before anything commits — the human-in-the-loop
//  step. Persisting to buyer memory arrives once the store is wired.
//

import Foundation
import Combine
import EventLog

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Phase: Equatable { case intro, recording, extracting, profile, complete }

    struct ProfileCard: Identifiable {
        let id = UUID()
        let proposal: PreferenceProposal
        var isOn: Bool = true
    }

    @Published private(set) var phase: Phase = .intro
    @Published private(set) var cards: [ProfileCard] = []
    @Published private(set) var savedCount = 0

    private let engine: any OnboardingExtracting
    private let onComplete: () -> Void
    private let events: EventLogger
    /// Correlates every event of one onboarding run.
    private let runID = UUID()

    init(onComplete: @escaping () -> Void,
         engine: any OnboardingExtracting = FixtureOnboardingEngine(),
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink())) {
        self.onComplete = onComplete
        self.engine = engine
        self.events = eventLogger
    }

    var keptCount: Int { cards.filter(\.isOn).count }

    // MARK: Intents

    func startTapped() {
        events.log("onboarding.started", traceID: runID)
        phase = .recording
    }

    /// The recording screen finished → run extraction on the captured transcript.
    func finishedRecording(transcript: String) {
        events.log("onboarding.recording_finished",
                   properties: ["chars": String(transcript.count)], traceID: runID)
        phase = .extracting
        devLog("onboarding: extracting from a \(transcript.count)-char transcript")
        Task { await runExtraction(transcript) }
    }

    func toggle(_ id: ProfileCard.ID) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index].isOn.toggle()
        events.log("onboarding.card_toggled",
                   properties: ["kept": String(keptCount)], traceID: runID)
    }

    func saveTapped() {
        savedCount = keptCount
        events.log("onboarding.saved",
                   properties: ["count": String(savedCount)], traceID: runID)
        devLog("onboarding: profile saved · \(savedCount) preference(s) confirmed")
        phase = .complete
    }

    func enterTapped() {
        events.log("onboarding.entered_app", traceID: runID)
        onComplete()
    }

    // MARK: Effect

    private func runExtraction(_ transcript: String) async {
        let draft = (try? await engine.extract(transcript: transcript)) ?? OnboardingDraft()
        cards = draft.preferences.map { ProfileCard(proposal: $0) }
        events.log("onboarding.extracted",
                   properties: ["count": String(cards.count)], traceID: runID)
        devLog("onboarding: extracted \(cards.count) preference(s)")
        phase = .profile
    }
}
