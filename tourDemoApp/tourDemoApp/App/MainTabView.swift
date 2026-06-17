//
//  MainTabView.swift
//  The three-tab main scope. The developer surface is NOT a tab — it's the global
//  shake-triggered overlay (see App/DevTools). Tab selection is bound to AppRouter
//  so a flow inside Today (the debrief) can hand the buyer to Compare on completion.
//

import SwiftUI

struct MainTabView: View {
    let container: AppDependencyContainer
    @ObservedObject var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            container.makeTodayView()
                .tabItem { Label(Strings.Tabs.today, systemImage: "house") }
                .tag(AppRouter.Tab.today)

            container.makeCompareView()
                .tabItem { Label(Strings.Tabs.compare, systemImage: "chart.bar.xaxis") }
                .tag(AppRouter.Tab.compare)

            container.makePlanView()
                .tabItem { Label(Strings.Tabs.plan, systemImage: "checklist") }
                .tag(AppRouter.Tab.plan)
        }
        .tint(AppColor.brandPrimary)
    }
}
