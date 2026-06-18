//
//  DebriefViewModel.swift
//  tourDemoApp — Modules/Features/Debrief/ViewModels
//
//  State-Driven MVVM for the per-home debrief (iOS architecture §1/§4/§5). Same
//  shape as onboarding, scoped to one home: record → extract → confirm → save.
//  The transcript runs through the debrief engine (fixture now; the ReAct agent in
//  Phase 3); each proposed profile change becomes a card the buyer confirms, and
//  only the kept set is committed via `BuyerMemoryStore.applyDebrief` — the human-
//  in-the-loop step. Per-home perceptions and the impression ride along unconfirmed
//  (they describe what was said, not a profile rewrite).
//

import Foundation
import Combine
import EventLog

@MainActor
final class DebriefViewModel: ObservableObject {
    enum Phase: Equatable { case recording, extracting, confirming, complete }

    struct PrefCard: Identifiable {
        let id = UUID()
        let proposal: PreferenceProposal
        var isOn: Bool = true
    }

    /// What the complete screen reports back.
    struct SavedSummary: Equatable {
        var preferences = 0
        var perceptions = 0
        var positives = 0
        var concerns = 0
    }

    @Published private(set) var phase: Phase = .recording
    @Published private(set) var draft = DebriefDraft()
    @Published private(set) var cards: [PrefCard] = []
    @Published private(set) var saved = SavedSummary()

    let home: Home
    private let engine: any DebriefExtracting
    private let events: EventLogger
    private let buyerMemory: BuyerMemoryStore
    /// Correlates every event of one debrief run.
    private let runID = UUID()
    private var didAppear = false

    // `engine` defaults to nil and is built in this @MainActor init body, not as a
    // default argument (those evaluate nonisolated, and FixtureDebriefEngine is
    // main-actor-isolated under SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor).
    // See [[swift-default-arg-isolation]].
    init(home: Home,
         engine: (any DebriefExtracting)? = nil,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore()) {
        self.home = home
        self.engine = engine ?? FixtureDebriefEngine()
        self.events = eventLogger
        self.buyerMemory = buyerMemory
    }

    /// The fixture script for this home — what the recorder streams (and the
    /// fallback if live capture is empty).
    var script: String { DebriefFixtures.fixture(for: home).transcript }

    /// The bundled audio clip to play for this home (per-house; Simulator/device).
    var audioResource: String { DebriefFixtures.fixture(for: home).audioResource }

    var keptCount: Int { cards.filter(\.isOn).count }

    // MARK: Intents

    func appeared() {
        guard !didAppear else { return }
        didAppear = true
        events.log("debrief.started", properties: ["home": home.address], traceID: runID)
    }

    func finishedRecording(transcript: String) {
        events.log("debrief.recording_finished",
                   properties: ["chars": String(transcript.count)], traceID: runID)
        phase = .extracting
        devLog("debrief: extracting from a \(transcript.count)-char transcript for \(home.address)")
        Task { await runExtraction(transcript) }
    }

    func toggle(_ id: PrefCard.ID) {
        guard let index = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[index].isOn.toggle()
        events.log("debrief.card_toggled",
                   properties: ["kept": String(keptCount)], traceID: runID)
    }

    func saveTapped() {
        // Commit only the confirmed profile changes; perceptions + the impression
        // ride along (they describe this home, not a global rewrite).
        var confirmed = draft
        confirmed.preferenceUpdates = cards.filter(\.isOn).map(\.proposal)
        buyerMemory.applyDebrief(confirmed, home: home)

        saved = SavedSummary(preferences: confirmed.preferenceUpdates.count,
                             perceptions: confirmed.perceptions.count,
                             positives: confirmed.positives.count,
                             concerns: confirmed.concerns.count)
        events.log("debrief.saved",
                   properties: ["home": home.address,
                                "preferences": String(saved.preferences),
                                "perceptions": String(saved.perceptions)],
                   traceID: runID)
        devLog("debrief: saved for \(home.address) · \(saved.preferences) profile change(s), "
               + "\(saved.perceptions) perception(s) · new profile [\(buyerMemory.summary)]")
        phase = .complete
    }

    // MARK: Effect

    private func runExtraction(_ transcript: String) async {
        let result = (try? await engine.extract(transcript: transcript, home: home)) ?? DebriefDraft()
        draft = result
        cards = result.preferenceUpdates.map { PrefCard(proposal: $0) }
        events.log("debrief.extracted",
                   properties: ["positives": String(result.positives.count),
                                "concerns": String(result.concerns.count),
                                "preference_updates": String(result.preferenceUpdates.count)],
                   traceID: runID)
        devLog("debrief: extracted \(result.positives.count) positive(s), "
               + "\(result.concerns.count) concern(s), \(result.preferenceUpdates.count) profile change(s)")
        phase = .confirming
    }
}
