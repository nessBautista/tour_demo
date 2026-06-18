//
//  AppEnvironment.swift
//  tourDemoApp — Modules/Core/Config
//
//  Core primitive: reads the config the app expects from the process environment.
//  Keys are supplied via the Xcode scheme's environment variables (the scheme
//  lives under xcshareddata/xcschemes/, which is gitignored — keys never get
//  committed). The container reads this once at launch; missing keys → fixtures,
//  so the app runs keyless (iOS architecture §3.1 / §6).
//
//  To run against live data, set these in the scheme (Edit Scheme → Run →
//  Arguments → Environment Variables):
//    SUPABASE_URL       = https://<project-ref>.supabase.co   (bare, no /rest/v1)
//    SUPABASE_ANON_KEY  = <the anon public JWT — eyJ…, never the service_role key>
//    OPENROUTER_API_KEY = <sk-or-… — enables the live extraction agent; absent → fixtures>
//    OPENROUTER_MODEL   = <optional model slug; default anthropic/claude-opus-4.8. Note
//                          OpenRouter uses DOTTED versions, e.g. anthropic/claude-haiku-4.5>
//
//  Deliberately pure and injectable: pass an explicit dictionary in tests; the
//  default initializer reads ProcessInfo.
//

import Foundation

struct AppEnvironment {

    /// The keys the app reads to run against live services. Each is independent —
    /// Supabase keys gate live listings, OPENROUTER_API_KEY gates the live agent;
    /// any one absent just falls back to fixtures for that piece.
    enum Key: String, CaseIterable {
        case supabaseURL      = "SUPABASE_URL"
        case supabaseAnonKey  = "SUPABASE_ANON_KEY"
        case openRouterAPIKey = "OPENROUTER_API_KEY"
        case openRouterModel  = "OPENROUTER_MODEL"
    }

    private let values: [String: String]

    /// Inject an explicit environment — used by tests with mock inputs.
    init(values: [String: String]) {
        self.values = values
    }

    /// Read from the current process environment (scheme-injected at launch).
    init(processInfo: ProcessInfo = .processInfo) {
        self.init(values: processInfo.environment)
    }

    /// The trimmed value for a key, or nil if absent or blank.
    func value(for key: Key) -> String? {
        guard let raw = values[key.rawValue] else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func isPresent(_ key: Key) -> Bool { value(for: key) != nil }

    var missingKeys: [Key] { Key.allCases.filter { !isPresent($0) } }

    var allKeysPresent: Bool { missingKeys.isEmpty }
}
