//
//  PlanView.swift
//  Dumb renderer — its own tab NavigationStack.
//

import SwiftUI

struct PlanView: View {
    @StateObject private var viewModel = PlanViewModel()

    var body: some View {
        NavigationStack {
            PlaceholderScreen(
                symbol: "checklist",
                title: Strings.Plan.title,
                message: Strings.Plan.message
            )
            .navigationTitle(Strings.Tabs.plan)
            .onAppear { viewModel.send(.appeared) }
        }
    }
}

#Preview {
    PlanView()
}
