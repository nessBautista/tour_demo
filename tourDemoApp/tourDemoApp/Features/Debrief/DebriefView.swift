//
//  DebriefView.swift
//  Dumb renderer — pushed onto Today's NavigationStack.
//

import SwiftUI

struct DebriefView: View {
    @StateObject private var viewModel = DebriefViewModel()

    var body: some View {
        PlaceholderScreen(
            symbol: "waveform",
            title: Strings.Debrief.title,
            message: Strings.Debrief.message
        )
        .navigationTitle(Strings.Debrief.navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.send(.appeared) }
    }
}

#Preview {
    NavigationStack { DebriefView() }
}
