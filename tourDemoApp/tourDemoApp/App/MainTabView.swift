//
//  MainTabView.swift
//  The three-tab main scope. The developer surface is NOT a tab — it's the global
//  shake-triggered overlay (see App/DevTools).
//

import SwiftUI

struct MainTabView: View {
    let container: AppDependencyContainer

    var body: some View {
        TabView {
            container.makeTodayView()
                .tabItem { Label(Strings.Tabs.today, systemImage: "house") }

            container.makeCompareView()
                .tabItem { Label(Strings.Tabs.compare, systemImage: "chart.bar.xaxis") }

            container.makePlanView()
                .tabItem { Label(Strings.Tabs.plan, systemImage: "checklist") }
        }
        .tint(AppColor.brandPrimary)
    }
}
