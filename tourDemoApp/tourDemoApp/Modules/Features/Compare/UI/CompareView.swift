//
//  CompareView.swift
//  tourDemoApp — Modules/Features/Compare/UI
//
//  Dumb renderer of CompareViewModel.state, in its own tab NavigationStack. Shows
//  toured homes ranked by fit, a one-line "why this order", and per-home a fit
//  badge + the dimension matches that explain it (FitScore.breakdown). The home a
//  debrief just touched is flagged "updated". No agent here — the order is the
//  deterministic FitScorer's; this screen narrates it.
//

import SwiftUI
import EventLog
import ComparisonCore

struct CompareView: View {
    @StateObject private var viewModel: CompareViewModel
    private let currentFocus: () -> UUID?
    /// Builds the buyer-memory panel pushed from the toolbar.
    private let memory: () -> BuyerMemoryView

    @State private var showMemory = false

    init(homesProvider: any HomesProviding,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore(),
         currentFocus: @escaping () -> UUID? = { nil },
         memory: @escaping () -> BuyerMemoryView = { BuyerMemoryView() }) {
        _viewModel = StateObject(wrappedValue: CompareViewModel(
            homesProvider: homesProvider, eventLogger: eventLogger, buyerMemory: buyerMemory))
        self.currentFocus = currentFocus
        self.memory = memory
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Strings.Tabs.compare)
                .background(AppColor.appBackground)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showMemory = true } label: {
                            Label(Strings.Compare.openMemory, systemImage: "brain")
                        }
                    }
                }
                .navigationDestination(isPresented: $showMemory) { memory() }
                .onAppear { viewModel.send(.appeared(focus: currentFocus())) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state.phase {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColor.appBackground)

        case .empty:
            PlaceholderScreen(
                symbol: "chart.bar.xaxis",
                title: Strings.Compare.title,
                message: Strings.Compare.message
            )

        case .ranked:
            ranked
        }
    }

    private var ranked: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                why

                ForEach(Array(viewModel.state.ranked.enumerated()), id: \.element.id) { index, scored in
                    CompareRankCard(
                        rank: index + 1,
                        scored: scored,
                        isFocused: scored.home.id == viewModel.state.focusHomeID
                    )
                }
            }
            .padding(Spacing.l)
        }
        .background(AppColor.appBackground)
    }

    private var why: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Strings.Compare.whyHeader)
                .font(Typography.eyebrow)
                .tracking(1.5)
                .foregroundStyle(AppColor.brandPrimary)
            Text(whyText)
                .font(Typography.serifBody)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// One deterministic line about the leader and its strongest dimension.
    private var whyText: String {
        guard let top = viewModel.state.ranked.first else { return "" }
        let name = shortName(top.home.address)
        guard let best = top.breakdown.max(by: { $0.match * $0.weight < $1.match * $1.weight }) else {
            return "\(name) leads at \(top.fitPercent)% fit."
        }
        return "\(name) leads at \(top.fitPercent)% — it scores strongest on "
            + "\(best.preference.dimension.rawValue), one of the things you weighted most."
    }
}

// MARK: - Rank card

private struct CompareRankCard: View {
    let rank: Int
    let scored: ScoredHome
    let isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            header

            if isFocused {
                Label(Strings.Compare.updated, systemImage: "sparkles")
                    .font(Typography.monoSmall.weight(.semibold))
                    .foregroundStyle(AppColor.brandPrimary)
            }

            VStack(spacing: 8) {
                ForEach(Array(scored.breakdown.enumerated()), id: \.offset) { _, match in
                    MatchBar(match: match)
                }
            }
        }
        .padding(Spacing.l)
        .background(AppColor.surface,
                    in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                .stroke(isFocused ? AppColor.brandPrimary : AppColor.divider,
                        lineWidth: isFocused ? 1.5 : 1)
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            Text("\(rank)")
                .font(Typography.title)
                .foregroundStyle(AppColor.textMuted)
            Text(shortName(scored.home.address))
                .font(Typography.title)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            Spacer(minLength: Spacing.s)
            Text("\(scored.fitPercent)% fit")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColor.onAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColor.brandPrimary, in: Capsule())
        }
    }
}

// MARK: - One dimension's match bar

private struct MatchBar: View {
    let match: DimensionMatch

    private var label: String {
        let arrow = match.preference.direction == .wantsMore ? "↑" : "↓"
        return "\(match.preference.dimension.rawValue) \(arrow)"
    }

    private var fill: Color {
        match.match >= 60 ? AppColor.success : (match.match >= 35 ? AppColor.highlight : AppColor.negative)
    }

    var body: some View {
        HStack(spacing: Spacing.s) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 78, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColor.surfaceSunken)
                    Capsule().fill(fill)
                        .frame(width: max(4, geo.size.width * CGFloat(match.match) / 100))
                }
            }
            .frame(height: 8)

            Text("\(match.match)")
                .font(Typography.monoSmall)
                .foregroundStyle(AppColor.textMuted)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

#Preview {
    CompareView(homesProvider: FixtureHomesService())
}
