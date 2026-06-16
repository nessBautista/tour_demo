/// Built-in fixtures so the CLI (and tests) can score something without a
/// backend. The three homes mirror the demo listings (same ids); the 0–100
/// ratings are illustrative stand-ins for what extraction will later produce.
public enum DemoData {

    public static let homes: [Home] = [
        Home(
            id: "00000000-0000-0000-0000-000000000001",
            address: "412 Alder Court, Maple Grove",
            ratings: [
                .yard: 90, .commute: 40, .quiet: 80,
                .kitchen: 75, .light: 85, .parking: 80, .budget: 70,
            ]
        ),
        Home(
            id: "00000000-0000-0000-0000-000000000002",
            address: "88 Foundry Lane #4B, Riverside District",
            ratings: [
                .yard: 0, .commute: 95, .quiet: 35,
                .kitchen: 90, .light: 50, .parking: 60, .budget: 45,
            ]
        ),
        Home(
            id: "00000000-0000-0000-0000-000000000003",
            address: "1735 Bellview Avenue, Old Town",
            ratings: [
                .yard: 55, .commute: 60, .quiet: 95,
                .kitchen: 25, .light: 40, .parking: 20, .budget: 85,
            ]
        ),
    ]

    /// A buyer who wants outdoor space and quiet, would take a shorter commute,
    /// and is mildly budget-conscious.
    public static let sampleProfile: [Preference] = [
        Preference(dimension: .yard, direction: .wantsMore, importance: .high),
        Preference(dimension: .quiet, direction: .wantsMore, importance: .medium),
        Preference(dimension: .commute, direction: .wantsMore, importance: .low),
        Preference(dimension: .budget, direction: .wantsMore, importance: .low),
    ]
}
