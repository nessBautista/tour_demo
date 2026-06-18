//
//  TodayView.swift
//  tourDemoApp — Modules/Features/Today/UI
//
//  The Today tab: the home listings, ranked by fit. A dumb renderer of
//  TodayViewModel.state — it switches over the load phase and lays out cards; all
//  data and intents go through `send` (iOS architecture §1). Each card carries the
//  per-home debrief entry point: a toured home shows "Record briefing" (pushes the
//  debrief onto this stack); an un-toured one shows a DEBUG-only "mark toured" so
//  the demo can advance state without the full tour-state machine (a later PR).
//

import SwiftUI
import EventLog

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    /// Builds the debrief flow for a home, given its close / see-compare callbacks.
    private let debrief: (Home, @escaping () -> Void, @escaping () -> Void) -> DebriefView
    /// Jump to Compare focused on a home (after a debrief).
    private let goToCompare: (UUID) -> Void

    @State private var debriefHome: Home?

    init(homesProvider: any HomesProviding,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore(),
         debrief: @escaping (Home, @escaping () -> Void, @escaping () -> Void) -> DebriefView = { home, _, _ in DebriefView(home: home) },
         goToCompare: @escaping (UUID) -> Void = { _ in }) {
        _viewModel = StateObject(wrappedValue: TodayViewModel(
            homesProvider: homesProvider, eventLogger: eventLogger, buyerMemory: buyerMemory))
        self.debrief = debrief
        self.goToCompare = goToCompare
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Strings.Tabs.today)
                .background(AppColor.appBackground)
                .navigationDestination(item: $debriefHome) { home in
                    debrief(home,
                            { debriefHome = nil; viewModel.send(.debriefReturned) },
                            { let id = home.id
                              debriefHome = nil
                              viewModel.send(.debriefReturned)
                              goToCompare(id) })
                }
                .onAppear { viewModel.send(.appeared) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state.phase {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.appBackground)

        case .failed(let message):
            PlaceholderScreen(
                symbol: "exclamationmark.triangle",
                title: Strings.Today.errorTitle,
                message: message,
                actionTitle: Strings.Today.retry,
                action: { viewModel.send(.retryTapped) }
            )

        case .loaded:
            if viewModel.state.scored.isEmpty {
                PlaceholderScreen(
                    symbol: "house",
                    title: Strings.Today.emptyTitle,
                    message: Strings.Today.emptyMessage
                )
            } else {
                listings
            }
        }
    }

    private var listings: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.l) {
                ForEach(viewModel.state.scored) { scored in
                    VStack(spacing: Spacing.s) {
                        HomeListCard(home: scored.home, fitPercent: scored.fitPercent)
                        footer(for: scored)
                    }
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.l)
        }
        .background(AppColor.appBackground)
    }

    /// Status pill + the one affordance for this home's funnel stage:
    /// notToured → Book a tour · booked → Record briefing · debriefed → Record another.
    @ViewBuilder
    private func footer(for scored: ScoredHome) -> some View {
        VStack(spacing: Spacing.s) {
            HStack {
                TourStatePill(state: scored.tourState, impressions: scored.impressionCount)
                Spacer(minLength: 0)
            }
            actionButton(for: scored)
        }
    }

    @ViewBuilder
    private func actionButton(for scored: ScoredHome) -> some View {
        switch scored.tourState {
        case .notToured:
            Button {
                viewModel.send(.bookTour(scored.home.id))
            } label: {
                Label(Strings.Tour.bookTour, systemImage: "calendar.badge.plus")
                    .font(Typography.subhead.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

        case .booked:
            Button {
                debriefHome = scored.home
            } label: {
                Label(Strings.Tour.recordBriefing, systemImage: "waveform")
                    .font(Typography.subhead.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

        case .debriefed:
            Button {
                debriefHome = scored.home
            } label: {
                Label(Strings.Tour.recordAnother, systemImage: "plus.bubble")
                    .font(Typography.subhead.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.pill, style: .continuous)
                            .stroke(AppColor.divider, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Tour-state pill

private struct TourStatePill: View {
    let state: TourState
    let impressions: Int

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
    }

    private var label: String {
        switch state {
        case .notToured: Strings.Tour.notToured
        case .booked:    Strings.Tour.booked
        case .debriefed: impressions > 0 ? "\(Strings.Tour.debriefed) · \(impressions)" : Strings.Tour.debriefed
        }
    }

    private var foreground: Color {
        switch state {
        case .notToured: AppColor.textMuted
        case .booked:    AppColor.onAccent
        case .debriefed: AppColor.onAccent
        }
    }

    private var background: Color {
        switch state {
        case .notToured: AppColor.surfaceSunken
        case .booked:    AppColor.highlight
        case .debriefed: AppColor.success
        }
    }
}

#Preview {
    TodayView(homesProvider: FixtureHomesService())
}
