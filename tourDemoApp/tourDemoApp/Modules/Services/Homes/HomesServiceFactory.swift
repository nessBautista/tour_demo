//
//  HomesServiceFactory.swift
//  tourDemoApp — Modules/Services/Homes
//
//  Picks the listings implementation from config: live Supabase when the keys are
//  present, fixtures otherwise (iOS architecture §6). The package owns this
//  construction knowledge; the container just asks for "the homes provider".
//

import Foundation

enum HomesServiceFactory {
    static func make(_ environment: AppEnvironment = AppEnvironment()) -> any HomesProviding {
        guard
            let urlString = environment.value(for: .supabaseURL),
            let url = URL(string: urlString),
            let anonKey = environment.value(for: .supabaseAnonKey)
        else {
            devLog("homes: Supabase keys missing → using fixtures", level: .warn)
            return FixtureHomesService()
        }
        devLog("homes: using live Supabase at \(url.host ?? urlString)")
        return SupabaseHomesService(baseURL: url, anonKey: anonKey)
    }
}
