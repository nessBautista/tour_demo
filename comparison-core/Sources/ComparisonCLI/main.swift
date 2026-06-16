import ComparisonCore
import Foundation

/// Command-line harness around `ComparisonCore`: parse a buyer profile from the
/// arguments, rank the demo homes, and print an explained result.
///
/// Pure orchestration — every bit of math lives in `FitScorer`; this struct only
/// reads arguments and formats output. `run(arguments:)` is the whole flow.
struct ComparisonCLI {

    // MARK: - Flow

    /// Parse arguments, rank the demo homes, and print the explained result.
    func run(arguments: [String]) {
        if arguments.contains("--help") || arguments.contains("-h") {
            print(Self.usage)
            exit(0)
        }

        let profile = parseProfile(from: arguments)
        let ranked = FitScorer(preferences: profile).rank(DemoData.homes)

        printProfile(profile)
        printRanking(ranked)
        if let top = ranked.first {
            explainWinner(top)
        }
    }

    // MARK: - Parsing

    /// Build the buyer profile from `--prefer` flags, falling back to the
    /// built-in sample profile when none are given.
    func parseProfile(from arguments: [String]) -> [Preference] {
        var custom: [Preference] = []
        var index = 0
        while index < arguments.count {
            switch arguments[index] {
            case "--prefer":
                guard index + 1 < arguments.count else { fail("--prefer needs a value") }
                custom.append(parsePreference(arguments[index + 1]))
                index += 2
            default:
                fail("unknown argument '\(arguments[index])' (try --help)")
            }
        }
        return custom.isEmpty ? DemoData.sampleProfile : custom
    }

    /// Parse one `<dim>:<dir>:<imp>` spec into a `Preference`.
    func parsePreference(_ spec: String) -> Preference {
        let parts = spec.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3 else {
            fail("--prefer expects <dim>:<dir>:<imp> (e.g. yard:more:high), got '\(spec)'")
        }
        guard let dimension = HomeDimension(rawValue: parts[0].lowercased()) else {
            fail("unknown dimension '\(parts[0])'")
        }
        let direction: Direction
        switch parts[1].lowercased() {
        case "more", "wantsmore": direction = .wantsMore
        case "less", "wantsless": direction = .wantsLess
        default: fail("direction must be 'more' or 'less', got '\(parts[1])'")
        }
        let importance: Importance
        switch parts[2].lowercased() {
        case "low": importance = .low
        case "med", "medium": importance = .medium
        case "high": importance = .high
        default: fail("importance must be low | med | high, got '\(parts[2])'")
        }
        return Preference(dimension: dimension, direction: direction, importance: importance)
    }

    // MARK: - Output

    func printProfile(_ profile: [Preference]) {
        print("Buyer profile:")
        for preference in profile {
            let direction = preference.direction == .wantsMore ? "wants more" : "wants less"
            let importance: String
            switch preference.importance {
            case .low: importance = "low"
            case .medium: importance = "medium"
            case .high: importance = "high"
            }
            print("  • \(padRight(preference.dimension.rawValue, 9)) \(padRight(direction, 11)) (\(importance))")
        }
    }

    func printRanking(_ ranked: [FitScore]) {
        print("\nRanked homes (best fit first):")
        for (index, score) in ranked.enumerated() {
            print("  \(index + 1). \(padRight(pct(score.fit), 7))  \(score.home.address)")
        }
    }

    func explainWinner(_ top: FitScore) {
        print("\nWhy \(top.home.address) wins:")
        var weightedSum = 0
        var totalWeight = 0
        for match in top.breakdown {
            let direction = match.preference.direction == .wantsMore ? "more" : "less"
            weightedSum += match.match * match.weight
            totalWeight += match.weight
            let line = "  \(padRight(match.preference.dimension.rawValue, 9)) "
                + "rating \(padNum(match.rating, 3))  (\(direction)) -> match \(padNum(match.match, 3)) "
                + "x weight \(match.weight) = \(padNum(match.match * match.weight, 3))"
            print(line)
        }
        print("  " + String(repeating: "-", count: 44))
        print("  fit = \(weightedSum) / \(totalWeight) = \(pct(top.fit))")
    }

    // MARK: - Formatting helpers

    /// Right-pad to a width for column alignment (ASCII labels only).
    func padRight(_ s: String, _ width: Int) -> String {
        s.count >= width ? s : s + String(repeating: " ", count: width - s.count)
    }

    /// Left-pad an integer for right-aligned numeric columns.
    func padNum(_ n: Int, _ width: Int) -> String {
        let s = String(n)
        return s.count >= width ? s : String(repeating: " ", count: width - s.count) + s
    }

    func pct(_ x: Double) -> String { String(format: "%.1f%%", x) }

    /// Print an error to stderr and exit non-zero.
    func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
        exit(2)
    }

    // MARK: - Usage

    static let usage = """
    comparison-cli — rank the demo homes by fit.

    USAGE:
      comparison-cli                              Rank using the built-in sample profile.
      comparison-cli --prefer <dim>:<dir>:<imp>   Build a custom profile (repeatable).
      comparison-cli --help

      <dim>  one of: yard commute quiet kitchen light parking budget note
      <dir>  more | less
      <imp>  low | med | high

    EXAMPLE:
      comparison-cli --prefer yard:more:high --prefer commute:more:low --prefer quiet:more:med
    """
}

// MARK: - Entry point

ComparisonCLI().run(arguments: Array(CommandLine.arguments.dropFirst()))
