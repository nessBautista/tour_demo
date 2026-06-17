//
//  DebriefView.swift
//  tourDemoApp — Modules/Features/Debrief/UI
//
//  The per-home debrief flow, pushed onto Today's NavigationStack. A dumb renderer
//  of DebriefViewModel.phase: record → extract → confirm → complete. The nav bar is
//  hidden so each step is the immersive full screen; progression is via the in-flow
//  buttons. `onClose` pops back to Today; `onSeeCompare` pops and jumps to Compare.
//

import SwiftUI
import EventLog

struct DebriefView: View {
    @StateObject private var viewModel: DebriefViewModel
    private let onClose: () -> Void
    private let onSeeCompare: () -> Void

    // `engine` is optional (nil → the VM builds the fixture in its @MainActor init);
    // a non-nil default here would evaluate nonisolated and fail to compile.
    init(home: Home,
         engine: (any DebriefExtracting)? = nil,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore(),
         onClose: @escaping () -> Void = {},
         onSeeCompare: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: DebriefViewModel(
            home: home, engine: engine, eventLogger: eventLogger, buyerMemory: buyerMemory))
        self.onClose = onClose
        self.onSeeCompare = onSeeCompare
    }

    var body: some View {
        ZStack {
            switch viewModel.phase {
            case .recording:
                VoiceRecordingView(
                    eyebrow: Strings.Debrief.eyebrow,
                    title: Strings.Debrief.recordTitle,
                    script: viewModel.script,
                    audioResource: "debrief_impression",
                    onFinish: { viewModel.finishedRecording(transcript: $0) }
                )
                .transition(.opacity)

            case .extracting:
                DebriefExtractingView()
                    .transition(.opacity)

            case .confirming:
                DebriefConfirmView(
                    homeName: homeName,
                    draft: viewModel.draft,
                    cards: viewModel.cards,
                    onToggle: { viewModel.toggle($0) },
                    onSave: { viewModel.saveTapped() }
                )
                .transition(.opacity)

            case .complete:
                DebriefCompleteView(
                    homeName: homeName,
                    saved: viewModel.saved,
                    onSeeCompare: onSeeCompare,
                    onDone: onClose
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.phase)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.appeared() }
    }

    /// The home's short name (text before the first comma), for headers/buttons.
    private var homeName: String {
        viewModel.home.address.split(separator: ",").first
            .map(String.init)?.trimmingCharacters(in: .whitespaces) ?? viewModel.home.address
    }
}

#Preview {
    NavigationStack {
        DebriefView(home: FixtureHomesService.demoHomes[0])
    }
}
