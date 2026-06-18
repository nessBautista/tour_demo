//
//  PlanViewModel.swift
//  tourDemoApp — Modules/Features/Plan/ViewModels
//
//  State-Driven MVVM for the Plan tab (iOS architecture §1/§4). Two halves, both
//  from real data:
//
//   • Next-best-actions — derived deterministically from the ranking + buyer memory
//     + tour state + open questions. The product's north star (a confident next
//     step after a tour) lives here: make an offer, book a second look, tour another
//     home, rule one out, ask the agent. With no booking backend, taking an action
//     emits its funnel event (the instrument-the-funnel principle) and confirms
//     locally — it does not mutate shared state.
//   • Activity feed — the in-app event log: the product milestones from the shared
//     EventLog store, newest first, with the north-star step starred.
//
//  Pull-based: it fetches homes and re-reads the event store on appear (§6).
//

import Foundation
import Combine
import EventLog

/// One grounded next step. `key` is stable across re-derivations so a taken action
/// stays "done" even as the list is rebuilt.
struct NextAction: Identifiable, Equatable {
    enum Kind: String, Equatable { case offer, secondLook, tour, ruleOut, askAgent, nudge }

    let id = UUID()
    let kind: Kind
    let title: String
    let detail: String
    let actionLabel: String
    let confirmedLabel: String
    let homeID: UUID?
    /// Funnel event emitted when taken (nil for a pure nudge).
    let eventName: String?
    let isNorthStar: Bool

    var key: String { "\(kind.rawValue)|\(homeID?.uuidString ?? "—")" }
}

/// One line of the user-facing activity feed (projected from a product Event).
struct ActivityRow: Identifiable, Equatable {
    let id: UUID
    let label: String
    let detail: String?
    let time: Date
    let isNorthStar: Bool
}

struct PlanState {
    var actions: [NextAction] = []
    var activity: [ActivityRow] = []
    /// Keys of actions already taken this session (show their confirmed state).
    var confirmed: Set<String> = []
    var loaded = false
}

enum PlanAction {
    case appeared
    case homesLoaded(Result<[Home], Error>)
    case take(NextAction)
}

@MainActor
final class PlanViewModel: ObservableObject {
    @Published private(set) var state = PlanState()

    private let homesProvider: any HomesProviding
    private let events: EventLogger
    private let buyerMemory: BuyerMemoryStore
    private let eventStore: InMemoryEventSink
    private var homes: [Home] = []

    init(homesProvider: any HomesProviding,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore(),
         eventStore: InMemoryEventSink) {
        self.homesProvider = homesProvider
        self.events = eventLogger
        self.buyerMemory = buyerMemory
        self.eventStore = eventStore
    }

    func send(_ action: PlanAction) {
        switch action {
        case .appeared:
            events.log("plan.appeared")
            // Re-derive every appear: the ranking/memory may have changed elsewhere.
            rebuildActivity()
            if homes.isEmpty { load() } else { state.actions = deriveActions() }

        case .homesLoaded(let result):
            state.loaded = true
            if case .success(let homes) = result { self.homes = homes }
            state.actions = deriveActions()
            rebuildActivity()

        case .take(let action):
            perform(action)
        }
    }

    // MARK: Taking an action

    private func perform(_ action: NextAction) {
        guard !state.confirmed.contains(action.key) else { return }
        if let name = action.eventName {
            var properties: [String: String] = [:]
            if let homeID = action.homeID, let home = homes.first(where: { $0.id == homeID }) {
                properties["home"] = home.address
            }
            events.log(name, properties: properties)
        }
        state.confirmed.insert(action.key)
        devLog("plan: \(action.kind.rawValue)\(action.isNorthStar ? " ★ north-star" : "")"
               + (action.homeID != nil ? " · \(action.title)" : ""))
        rebuildActivity()
    }

    // MARK: Deriving the actions

    private func deriveActions() -> [NextAction] {
        var out: [NextAction] = []
        let ranked = buyerMemory.ranked(homes)
        let toured = ranked.filter(\.isToured)

        // 1) The leader: offer if it's a clear winner over a real runner-up, else a
        //    second look (the north-star step). One toured home can't be "clear".
        if let leader = toured.first {
            let name = shortName(leader.home.address)
            let runnerUp = toured.dropFirst().first
            let debriefed = !buyerMemory.impressions(for: leader.home.id).isEmpty
            if debriefed, let runnerUp, leader.fit - runnerUp.fit >= 12 {
                out.append(NextAction(
                    kind: .offer,
                    title: "Make an offer on \(name)",
                    detail: "\(leader.fitPercent)% fit — well clear of the rest. This is the decisive move.",
                    actionLabel: "Log offer", confirmedLabel: "Offer logged",
                    homeID: leader.home.id, eventName: "plan.offer_made", isNorthStar: false))
            } else {
                out.append(NextAction(
                    kind: .secondLook,
                    title: "Book a second look at \(name)",
                    detail: "Your top-ranked toured home (\(leader.fitPercent)% fit) — get back in to confirm it.",
                    actionLabel: "Book", confirmedLabel: "Requested",
                    homeID: leader.home.id, eventName: "plan.second_look_requested", isNorthStar: true))
            }
        }

        // 2) Tour the best-fitting home you haven't seen.
        if let best = ranked.first(where: { !$0.isToured }) {
            out.append(NextAction(
                kind: .tour,
                title: "Tour \(shortName(best.home.address))",
                detail: "Not toured yet · fits your profile at \(best.fitPercent)%.",
                actionLabel: "Book tour", confirmedLabel: "Requested",
                homeID: best.home.id, eventName: "plan.tour_requested", isNorthStar: false))
        }

        // 3) Rule out a toured home that's well off the pace.
        if let leader = toured.first, let worst = toured.last,
           worst.home.id != leader.home.id, leader.fit - worst.fit >= 25, worst.fit < 45 {
            out.append(NextAction(
                kind: .ruleOut,
                title: "Rule out \(shortName(worst.home.address))",
                detail: "\(worst.fitPercent)% fit — well below your top pick. Clearing it sharpens the race.",
                actionLabel: "Rule out", confirmedLabel: "Ruled out",
                homeID: worst.home.id, eventName: "plan.ruled_out", isNorthStar: false))
        }

        // 4) Ask the agent an open question a debrief surfaced.
        if let question = firstOpenQuestion() {
            out.append(NextAction(
                kind: .askAgent,
                title: "Ask your agent",
                detail: "“\(question.text)” — from your debrief of \(shortName(question.address)).",
                actionLabel: "Mark asked", confirmedLabel: "Flagged",
                homeID: nil, eventName: "plan.question_flagged", isNorthStar: false))
        }

        // Fallback: nothing toured yet.
        if out.isEmpty {
            out.append(NextAction(
                kind: .nudge,
                title: "Record an impression after your next tour",
                detail: "The faster you debrief, the sharper your ranking — and the clearer your next move.",
                actionLabel: "Got it", confirmedLabel: "Got it",
                homeID: nil, eventName: nil, isNorthStar: false))
        }
        return out
    }

    /// The earliest open question across all debriefs (deterministic by time).
    private func firstOpenQuestion() -> (text: String, address: String)? {
        buyerMemory.impressions.values
            .flatMap { $0 }
            .sorted { $0.recordedAt < $1.recordedAt }
            .compactMap { impression in impression.openQuestions.first.map { ($0, impression.address) } }
            .first
    }

    // MARK: Activity feed

    private func rebuildActivity() {
        state.activity = eventStore.events.reversed().compactMap(milestone(for:))
    }

    /// Project a product Event onto a friendly activity row — nil for the noisy
    /// micro-events (appeared / toggled / loaded) that aren't milestones.
    private func milestone(for event: Event) -> ActivityRow? {
        let p = event.properties
        func row(_ label: String, _ detail: String? = nil, northStar: Bool = false) -> ActivityRow {
            ActivityRow(id: event.id, label: label, detail: detail,
                        time: event.timestamp, isNorthStar: northStar)
        }
        switch event.name {
        case "onboarding.saved":
            return row("Set up your buyer profile", p["count"].map { "\($0) preferences" })
        case "today.tour_booked":
            return row("Booked a tour", shortNameOrNil(p["home"]))
        case "debrief.saved":
            return row("Debriefed a home", shortNameOrNil(p["home"]))
        case "memory.promoted":
            return row("Promoted “\(p["dimension"] ?? "a preference")” in memory")
        case "plan.second_look_requested":
            return row("Requested a second look", shortNameOrNil(p["home"]), northStar: true)
        case "plan.offer_made":
            return row("Logged an offer", shortNameOrNil(p["home"]))
        case "plan.tour_requested":
            return row("Requested a tour", shortNameOrNil(p["home"]))
        case "plan.ruled_out":
            return row("Ruled a home out", shortNameOrNil(p["home"]))
        case "plan.question_flagged":
            return row("Flagged a question for your agent")
        default:
            return nil
        }
    }

    private func shortNameOrNil(_ address: String?) -> String? {
        address.map(shortName)
    }

    // MARK: Effect

    private func load() {
        let provider = homesProvider
        Task { @MainActor [weak self] in
            do {
                let homes = try await provider.fetchHomes()
                self?.send(.homesLoaded(.success(homes)))
            } catch {
                self?.send(.homesLoaded(.failure(error)))
            }
        }
    }
}
