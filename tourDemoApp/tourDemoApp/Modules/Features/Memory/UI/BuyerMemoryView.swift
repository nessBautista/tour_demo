//
//  BuyerMemoryView.swift
//  tourDemoApp — Modules/Features/Memory/UI
//
//  The buyer-memory panel, pushed from Compare. A dumb renderer of the snapshot:
//  the profile, recurrence-driven promote cards ("mentioned at 3/3 homes"), any
//  contradictions, and the per-home impression stream. Promoting is a confirmation
//  card — accepting it writes to memory and re-ranks (visible back on Compare).
//

import SwiftUI
import EventLog
import ComparisonCore

struct BuyerMemoryView: View {
    @StateObject private var viewModel: BuyerMemoryViewModel

    init(buyerMemory: BuyerMemoryStore = BuyerMemoryStore(),
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink())) {
        _viewModel = StateObject(wrappedValue: BuyerMemoryViewModel(
            buyerMemory: buyerMemory, eventLogger: eventLogger))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                heading

                if !viewModel.snapshot.suggestions.isEmpty {
                    promoteSection
                }

                profileSection

                if !viewModel.snapshot.contradictions.isEmpty {
                    contradictionsSection
                }

                impressionsSection
            }
            .padding(Spacing.l)
        }
        .background(AppColor.appBackground)
        .navigationTitle(Strings.Memory.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.appeared() }
    }

    // MARK: Heading

    private var heading: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Strings.Memory.title)
                .font(Typography.heading)
                .foregroundStyle(AppColor.textPrimary)
            Text(Strings.Memory.subtitle)
                .font(Typography.subhead)
                .foregroundStyle(AppColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Promote

    private var promoteSection: some View {
        section(Strings.Memory.promoteHeader) {
            ForEach(viewModel.snapshot.suggestions) { suggestion in
                PromoteCard(suggestion: suggestion,
                            onPromote: { viewModel.promote(suggestion) },
                            onDismiss: { viewModel.dismiss(suggestion) })
            }
        }
    }

    // MARK: Profile

    private var profileSection: some View {
        section(Strings.Memory.profileHeader) {
            VStack(spacing: 8) {
                ForEach(viewModel.snapshot.preferences, id: \.dimension) { preference in
                    PreferenceRow(preference: preference)
                }
            }
        }
    }

    // MARK: Contradictions

    private var contradictionsSection: some View {
        section(Strings.Memory.contradictionsHeader) {
            VStack(spacing: 8) {
                ForEach(viewModel.snapshot.contradictions) { contradiction in
                    ContradictionRow(contradiction: contradiction)
                }
            }
        }
    }

    // MARK: Impressions

    private var impressionsSection: some View {
        section(Strings.Memory.impressionsHeader) {
            if viewModel.snapshot.impressions.isEmpty {
                Text(Strings.Memory.emptyImpressions)
                    .font(Typography.subhead)
                    .foregroundStyle(AppColor.textMuted)
            } else {
                VStack(spacing: Spacing.m) {
                    ForEach(viewModel.snapshot.impressions) { impression in
                        ImpressionRow(impression: impression)
                    }
                }
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

// MARK: - Promote card

private struct PromoteCard: View {
    let suggestion: PromoteSuggestion
    var onPromote: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(suggestion.dimension.rawValue.capitalized)
                    .font(Typography.bodyLarge.weight(.semibold))
                    .foregroundStyle(AppColor.textPrimary)
                Spacer(minLength: Spacing.s)
                Text("\(suggestion.mentionedHomes)/\(suggestion.totalHomes) homes")
                    .font(Typography.monoSmall)
                    .foregroundStyle(AppColor.brandPrimary)
            }

            Text(changeText)
                .font(Typography.subhead)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.s) {
                Button(action: onPromote) {
                    Text(Strings.Memory.promote)
                        .font(Typography.subhead.weight(.semibold))
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, 8)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(action: onDismiss) {
                    Text(Strings.Memory.dismiss)
                        .font(Typography.subhead)
                        .foregroundStyle(AppColor.textMuted)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.l)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                .stroke(AppColor.brandPrimary.opacity(0.4), lineWidth: 1)
        )
    }

    private var changeText: String {
        let kind = importanceLabel(suggestion.proposedImportance).lowercased()
        if suggestion.isNew {
            let lean = suggestion.proposedDirection == .wantsMore ? "more" : "less"
            return "You keep mentioning it — add it as a \(kind) (you want \(lean) of it)."
        } else {
            return "You keep mentioning it — make it a \(kind)."
        }
    }
}

// MARK: - Profile row

private struct PreferenceRow: View {
    let preference: Preference

    var body: some View {
        HStack(spacing: Spacing.m) {
            Text(preference.dimension.rawValue.capitalized)
                .font(Typography.bodyLarge)
                .foregroundStyle(AppColor.textPrimary)
            Text(preference.direction == .wantsMore ? "wants more" : "wants less")
                .font(Typography.caption)
                .foregroundStyle(AppColor.textMuted)
            Spacer(minLength: Spacing.s)
            importanceBadge
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }

    private var importanceBadge: some View {
        Text(importanceLabel(preference.importance))
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(preference.importance == .high ? AppColor.onAccent : AppColor.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(preference.importance == .high ? AppColor.brandPrimary : AppColor.surfaceSunken,
                        in: Capsule())
            .fixedSize()
    }
}

// MARK: - Contradiction row

private struct ContradictionRow: View {
    let contradiction: Contradiction

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColor.highlight)
            Text("\(contradiction.dimension.rawValue.capitalized) — you wanted "
                 + "\(dir(contradiction.previous)), now want \(dir(contradiction.latest)).")
                .font(Typography.subhead)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppColor.highlight.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
    }

    private func dir(_ preference: Preference) -> String {
        preference.direction == .wantsMore ? "more" : "less"
    }
}

// MARK: - Impression row

private struct ImpressionRow: View {
    let impression: Impression

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(shortName(impression.address))
                .font(Typography.title)
                .foregroundStyle(AppColor.textPrimary)

            if !impression.summary.isEmpty {
                Text("“\(impression.summary)”")
                    .font(Typography.subhead.italic())
                    .foregroundStyle(AppColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Array(impression.positives.enumerated()), id: \.offset) { _, text in
                marker(text, symbol: "plus", color: AppColor.success)
            }
            ForEach(Array(impression.concerns.enumerated()), id: \.offset) { _, text in
                marker(text, symbol: "minus", color: AppColor.negative)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.l)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                .stroke(AppColor.divider, lineWidth: 1)
        )
    }

    private func marker(_ text: String, symbol: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
                .padding(.top, 3)
            Text(text)
                .font(Typography.subhead)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Shared

/// MUST-HAVE / NICE-TO-HAVE / MINOR for an importance.
private func importanceLabel(_ importance: Importance) -> String {
    switch importance {
    case .high:   "MUST-HAVE"
    case .medium: "NICE-TO-HAVE"
    case .low:    "MINOR"
    }
}

#Preview {
    NavigationStack {
        BuyerMemoryView()
    }
}
