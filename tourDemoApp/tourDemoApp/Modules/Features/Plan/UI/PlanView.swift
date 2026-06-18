//
//  PlanView.swift
//  tourDemoApp — Modules/Features/Plan/UI
//
//  The Plan tab: a dumb renderer of PlanViewModel.state. Up top, the grounded
//  next-best-action cards (the product's north star — a confident next step);
//  below, the user-facing activity feed (the funnel, live). Taking an action goes
//  through `send` and emits its funnel event; the card then shows its confirmed
//  state. No booking backend — the event IS the outcome we measure.
//

import SwiftUI
import EventLog

struct PlanView: View {
    @StateObject private var viewModel: PlanViewModel

    init(homesProvider: any HomesProviding,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore(),
         eventStore: InMemoryEventSink) {
        _viewModel = StateObject(wrappedValue: PlanViewModel(
            homesProvider: homesProvider, eventLogger: eventLogger,
            buyerMemory: buyerMemory, eventStore: eventStore))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    heading
                    actionsSection
                    activitySection
                }
                .padding(Spacing.l)
            }
            .background(AppColor.appBackground)
            .navigationTitle(Strings.Tabs.plan)
            .onAppear { viewModel.send(.appeared) }
        }
    }

    // MARK: Heading

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Strings.Plan.heading)
                .font(Typography.heading)
                .foregroundStyle(AppColor.textPrimary)
            Text(Strings.Plan.subtitle)
                .font(Typography.subhead)
                .foregroundStyle(AppColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Actions

    private var actionsSection: some View {
        section(Strings.Plan.actionsHeader) {
            VStack(spacing: Spacing.m) {
                ForEach(viewModel.state.actions) { action in
                    NextActionCard(
                        action: action,
                        isConfirmed: viewModel.state.confirmed.contains(action.key),
                        onTake: { viewModel.send(.take(action)) }
                    )
                }
            }
        }
    }

    // MARK: Activity

    private var activitySection: some View {
        section(Strings.Plan.activityHeader) {
            if viewModel.state.activity.isEmpty {
                Text(Strings.Plan.activityEmpty)
                    .font(Typography.subhead)
                    .foregroundStyle(AppColor.textMuted)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.state.activity) { row in
                        ActivityRowView(row: row)
                        if row.id != viewModel.state.activity.last?.id {
                            Divider().overlay(AppColor.divider)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                        .stroke(AppColor.divider, lineWidth: 1)
                )
            }
        }
    }

    // MARK: Section scaffold

    @ViewBuilder
    private func section<Content: View>(_ header: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(header)
                .font(Typography.eyebrow)
                .tracking(1.5)
                .foregroundStyle(AppColor.brandPrimary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Next-action card

private struct NextActionCard: View {
    let action: NextAction
    let isConfirmed: Bool
    var onTake: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if action.isNorthStar {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.highlight)
                }
                Text(action.title)
                    .font(Typography.bodyLarge.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(action.detail)
                .font(Typography.subhead)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if isConfirmed {
                Label(action.confirmedLabel, systemImage: "checkmark.circle.fill")
                    .font(Typography.subhead.weight(.semibold))
                    .foregroundStyle(AppColor.success)
                    .padding(.top, 2)
            } else {
                Button(action: onTake) {
                    Text(action.actionLabel)
                        .font(Typography.subhead.weight(.semibold))
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, 8)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                .stroke(action.isNorthStar ? AppColor.highlight.opacity(0.5) : AppColor.divider,
                        lineWidth: action.isNorthStar ? 1.5 : 1)
        )
    }
}

// MARK: - Activity row

private struct ActivityRowView: View {
    let row: ActivityRow

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.m) {
            Image(systemName: row.isNorthStar ? "star.fill" : "circle.fill")
                .font(.system(size: row.isNorthStar ? 10 : 5))
                .foregroundStyle(row.isNorthStar ? AppColor.highlight : AppColor.brandPrimary)
                .frame(width: 14, alignment: .center)

            VStack(alignment: .leading, spacing: 1) {
                Text(row.label)
                    .font(Typography.subhead.weight(.medium))
                    .foregroundStyle(AppColor.textPrimary)
                if let detail = row.detail {
                    Text(detail)
                        .font(Typography.caption)
                        .foregroundStyle(AppColor.textMuted)
                }
            }

            Spacer(minLength: Spacing.s)

            Text(row.time, style: .time)
                .font(Typography.monoSmall)
                .foregroundStyle(AppColor.textMuted)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    PlanView(homesProvider: FixtureHomesService(), eventStore: InMemoryEventSink())
}
