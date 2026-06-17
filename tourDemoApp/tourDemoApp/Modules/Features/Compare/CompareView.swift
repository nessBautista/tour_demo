//
//  CompareView.swift
//  Dumb renderer — its own tab NavigationStack.
//

import SwiftUI

struct CompareView: View {
    @StateObject private var viewModel = CompareViewModel()

    var body: some View {
        NavigationStack {
            PlaceholderScreen(
                symbol: "chart.bar.xaxis",
                title: Strings.Compare.title,
                message: Strings.Compare.message
            )
            .navigationTitle(Strings.Tabs.compare)
            .onAppear { viewModel.send(.appeared) }
        }
    }
}

#Preview {
    CompareView()
}
