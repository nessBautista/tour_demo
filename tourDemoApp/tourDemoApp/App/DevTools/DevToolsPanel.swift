//
//  DevToolsPanel.swift
//  tourDemoApp — App/DevTools
//
//  The DEBUG-only overlay UI: a floating card over a dimmed backdrop, with a
//  segmented switch between demo actions, the palette switcher, the design-token
//  gallery, and the live logs feed.
//

#if DEBUG
import SwiftUI
import EventLog

struct DevToolsPanel: View {
    @Bindable var dev: DevTools
    @State private var tab: Tab = .events

    enum Tab: String, CaseIterable, Identifiable {
        case actions = "Actions"
        case events = "Events"
        case theme = "Palette"
        case tokens = "Tokens"
        case logs = "Logs"
        var id: String { rawValue }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            VStack(spacing: 0) {
                header
                Picker("Section", selection: $tab) {
                    ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                Divider()

                switch tab {
                case .actions: DevActionsView(dev: dev, onRan: close)
                case .events: DevEventsView(store: dev.eventStore)
                case .theme: DevThemeView()
                case .tokens: DevTokenGallery()
                case .logs: DevLogView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 8)
            .padding(.top, 64)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var header: some View {
        HStack {
            Label("Developer Tools", systemImage: "wrench.and.screwdriver")
                .font(.headline)
            Spacer()
            Button(action: close) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Close developer tools")
        }
        .padding()
    }

    private func close() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            dev.isPresented = false
        }
    }
}

// MARK: - Demo actions

private struct DevActionsView: View {
    let dev: DevTools
    let onRan: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Demo")
                    .font(.headline)

                if let reset = dev.onResetDemo {
                    Button(role: .destructive) {
                        onRan()
                        reset()
                    } label: {
                        Label("Reset demo (restart onboarding)", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("No demo actions registered.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Tour-state toggles (notToured → booked → debriefed) land here once feat/tour-state exists.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Event stream (EventLog)

private struct DevEventsView: View {
    let store: InMemoryEventSink?
    @State private var events: [Event] = []

    private var summary: InferenceSummary {
        events.inferenceSummary(pricing: .anthropicJune2026)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if store == nil {
                ContentUnavailableView("No store wired", systemImage: "bolt.horizontal.circle")
                    .frame(maxHeight: .infinity)
            } else if events.isEmpty {
                ContentUnavailableView(
                    "No events yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Walk the onboarding or Today flow, then reopen.")
                )
                .frame(maxHeight: .infinity)
            } else {
                list
            }
        }
        .onAppear(perform: reload)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                .font(.caption).foregroundStyle(.secondary)
            if summary.calls > 0 {
                Text("· \(summary.calls) inference · \(summary.totalTokens) tok · \(costText)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Refresh", action: reload).font(.caption)
            Button("Clear") { store?.clear(); reload() }
                .font(.caption).disabled(events.isEmpty)
        }
        .padding(.horizontal).padding(.vertical, 8)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(events.reversed()) { event in
                    EventRow(event: event)
                    Divider()
                }
            }
        }
    }

    private var costText: String {
        "$" + String(format: "%.4f", summary.totalCostUSD)
    }

    private func reload() {
        events = store?.events ?? []
    }
}

private struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(badge).font(.caption2.monospaced())
                .foregroundStyle(color)
                .frame(width: 22, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                if let detail { Text(detail).font(.caption2).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 0)
            Text(event.timestamp, style: .time).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal).padding(.vertical, 6)
    }

    private var badge: String {
        switch event.category {
        case .product:   "•"
        case .inference: "∑"
        case .system:    "⚙"
        }
    }

    private var color: Color {
        switch event.category {
        case .product:   .blue
        case .inference: .purple
        case .system:    .secondary
        }
    }

    private var detail: String? {
        var parts: [String] = []
        if let m = event.inference {
            parts.append("\(m.model) · \(m.totalTokens) tok · \(m.latencyMS) ms")
        }
        if !event.properties.isEmpty {
            parts.append(event.properties.sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }.joined(separator: " "))
        }
        return parts.isEmpty ? nil : parts.joined(separator: "  ·  ")
    }
}

// MARK: - Palette switcher

private struct DevThemeView: View {
    @State private var theme = Theme.shared

    var body: some View {
        @Bindable var theme = theme
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Palette", selection: $theme.kind) {
                    ForEach(PaletteKind.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                Text("Active palette: \(theme.kind.label). Changes apply live across the whole app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                preview("Cold", .cold)
                preview("Warm", .warm)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func preview(_ name: String, _ palette: Palette) -> some View {
        let swatches: [Color] = [
            palette.brandPrimary, palette.brandPrimaryDark, palette.highlight,
            palette.success, palette.appBackground, palette.surface,
            palette.textPrimary, palette.divider,
        ]
        VStack(alignment: .leading, spacing: 8) {
            Text(name).font(.headline)
            HStack(spacing: 6) {
                ForEach(Array(swatches.enumerated()), id: \.offset) { _, color in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(.black.opacity(0.12))
                        )
                }
            }
        }
    }
}

// MARK: - Token gallery

private struct DevTokenGallery: View {
    private let colors: [(String, Color)] = [
        ("brandPrimary", AppColor.brandPrimary),
        ("brandPrimaryLight", AppColor.brandPrimaryLight),
        ("brandPrimaryDark", AppColor.brandPrimaryDark),
        ("brandTint", AppColor.brandTint),
        ("success", AppColor.success),
        ("successTint", AppColor.successTint),
        ("negative", AppColor.negative),
        ("negativeTint", AppColor.negativeTint),
        ("highlight", AppColor.highlight),
        ("textPrimary", AppColor.textPrimary),
        ("textSecondary", AppColor.textSecondary),
        ("textMuted", AppColor.textMuted),
        ("onAccent", AppColor.onAccent),
        ("appBackground", AppColor.appBackground),
        ("surface", AppColor.surface),
        ("surfaceSunken", AppColor.surfaceSunken),
        ("divider", AppColor.divider),
        ("surfaceDark", AppColor.surfaceDark),
        ("onSurfaceDark", AppColor.onSurfaceDark),
        ("onSurfaceDarkMuted", AppColor.onSurfaceDarkMuted),
    ]

    private let specimens: [(String, Font)] = [
        ("display", Typography.display),
        ("heading", Typography.heading),
        ("title", Typography.title),
        ("serifBody", Typography.serifBody),
        ("bodyLarge", Typography.bodyLarge),
        ("body", Typography.body),
        ("subhead", Typography.subhead),
        ("caption", Typography.caption),
        ("micro", Typography.micro),
        ("eyebrow", Typography.eyebrow),
        ("mono", Typography.mono),
        ("monoSmall", Typography.monoSmall),
    ]

    private let grid = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                section("Colors") {
                    LazyVGrid(columns: grid, spacing: 12) {
                        ForEach(colors, id: \.0) { name, color in
                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(color)
                                    .frame(height: 52)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(.black.opacity(0.12))
                                    )
                                Text(name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                    }
                }

                section("Typography") {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(specimens, id: \.0) { name, font in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("The quick brown fox")
                                    .font(font)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                Text(name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content()
        }
    }
}

// MARK: - Logs feed

private struct DevLogView: View {
    @State private var log = DevLog.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(log.entries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Clear") { log.clear() }
                    .font(.caption)
                    .disabled(log.entries.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            Divider()

            if log.entries.isEmpty {
                ContentUnavailableView(
                    "No logs yet",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Calls to devLog(\"…\") show up here, newest first.")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(log.entries) { entry in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(entry.level.badge)
                                    .font(.caption2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.message)
                                        .font(.system(.caption, design: .monospaced))
                                        .textSelection(.enabled)
                                    Text(entry.date, style: .time)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private extension DevLogLevel {
    var badge: String {
        switch self {
        case .debug: "·"
        case .info:  "ℹ︎"
        case .warn:  "⚠︎"
        case .error: "⛔︎"
        }
    }
}

#endif
