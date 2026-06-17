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

    @ViewBuilder
    private func footer(for scored: ScoredHome) -> some View {
        if scored.isToured {
            Button {
                debriefHome = scored.home
            } label: {
                Label(Strings.Debrief.record, systemImage: "waveform")
                    .font(Typography.subhead.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        } else {
            #if DEBUG
            Button {
                viewModel.send(.markToured(scored.home.id))
            } label: {
                Label(Strings.Debrief.markToured, systemImage: "hammer")
                    .font(Typography.monoSmall)
                    .foregroundStyle(AppColor.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                            .stroke(AppColor.divider, style: StrokeStyle(lineWidth: 1, dash: [4]))
                    )
                    // Hit-test the whole frame, not just the centered glyphs.
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            #endif
        }
    }
}

#Preview {
    TodayView(homesProvider: FixtureHomesService())
}
