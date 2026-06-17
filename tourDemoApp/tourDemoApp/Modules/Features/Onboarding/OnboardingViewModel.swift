//
//  OnboardingViewModel.swift
//  Onboarding feature — State / Action / ViewModel (iOS architecture §4).
//
//  Shell stage: no voice capture yet. The quartet exists so feat/voice-extraction
//  and the extraction flow slot in without restructuring.
//

import Combine
import Foundation

struct OnboardingState {
    enum Phase { case intro }   // recording / transcribing / confirming arrive later
    var phase: Phase = .intro
}

enum OnboardingAction {
    case appeared
    case finishTapped
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var state = OnboardingState()
    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func send(_ action: OnboardingAction) {
        switch action {
        case .appeared:
            break
        case .finishTapped:
            onComplete()
        }
    }
}
