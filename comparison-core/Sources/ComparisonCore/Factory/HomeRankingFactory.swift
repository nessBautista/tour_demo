import Foundation

/// Builds the ``HomeRanking`` the app should use.
///
/// There's one ranking strategy today — ``FitScorer`` — so, unlike a
/// platform-selecting factory, this doesn't *choose* between implementations.
/// It earns its place as:
///
/// 1. the **single construction point** for a ranker, and
/// 2. the **composability seam** — it hands back `any HomeRanking`, so callers
///    depend on the capability, not the concrete struct. A smarter or stubbed
///    strategy can be dropped in here later without touching them.
///
/// (Same division as the backend / voice factories: the package decides how a
/// capability is built; the app just asks for one.)
public enum HomeRankingFactory {

    /// The default ranker for a buyer's profile.
    ///
    /// - Parameter preferences: the buyer's profile. May be empty (every home
    ///   then scores 0 — there's nothing to satisfy).
    public static func makeDefault(preferences: [Preference]) -> any HomeRanking {
        FitScorer(preferences: preferences)
    }

    /// A ranker wired to the built-in demo profile — handy for previews, the
    /// CLI, and tests that just need *a* working ranking with no setup.
    public static func makeDemo() -> any HomeRanking {
        FitScorer(preferences: DemoData.sampleProfile)
    }
}
