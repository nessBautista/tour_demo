//
//  OnboardingView.swift
//  tourDemoApp — Modules/Features/Onboarding/UI
//
//  Onboarding scope: intro → record → extract → confirm profile → enter app.
//  A dumb renderer of OnboardingViewModel.phase. The recording screen hands back a
//  transcript; the VM runs extraction and builds the confirmation cards. Calls
//  onComplete (the root scope switch) when the buyer enters the app.
//

import SwiftUI
import EventLog

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init(onComplete: @escaping () -> Void,
         eventLogger: EventLogger = EventLogger(sink: NoOpEventSink()),
         buyerMemory: BuyerMemoryStore = BuyerMemoryStore()) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(
            onComplete: onComplete, eventLogger: eventLogger, buyerMemory: buyerMemory))
    }

    var body: some View {
        ZStack {
            switch viewModel.phase {
            case .intro:
                OnboardingIntroView(onStartTapped: { viewModel.startTapped() })
                    .transition(.opacity)

            case .recording:
                VoiceRecordingView(
                    eyebrow: Strings.Onboarding.eyebrow,
                    title: Strings.Onboarding.title,
                    script: OnboardingFixtures.standard.transcript,
                    onFinish: { viewModel.finishedRecording(transcript: $0) }
                )
                .transition(.opacity)

            case .extracting:
                OnboardingExtractingView()
                    .transition(.opacity)

            case .profile:
                OnboardingProfileView(
                    cards: viewModel.cards,
                    onToggle: { viewModel.toggle($0) },
                    onSave: { viewModel.saveTapped() }
                )
                .transition(.opacity)

            case .complete:
                OnboardingCompleteView(
                    savedCount: viewModel.savedCount,
                    onEnter: { viewModel.enterTapped() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.phase)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
