//
//  TodayView.swift
//  tourDemoApp — Modules/Features/Today/UI
//
//  The Today tab: the home listings. A dumb renderer of TodayViewModel.state —
//  it switches over the load phase and lays out cards; all data and intents go
//  through `send` (iOS architecture §1). No tour state / actions yet — this is the
//  first feature, just the listings.
//

import SwiftUI
import EventLog

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel

    init(homesProvider: any HomesProviding,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore()) {
        _viewModel = StateObject(wrappedValue: TodayViewModel(
            homesProvider: homesProvider, eventLogger: eventLogger, buyerMemory: buyerMemory))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Strings.Tabs.today)
                .background(AppColor.appBackground)
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
                    HomeListCard(home: scored.home, fitPercent: scored.fitPercent)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.l)
        }
        .background(AppColor.appBackground)
    }
}

#Preview {
    TodayView(homesProvider: FixtureHomesService())
}
