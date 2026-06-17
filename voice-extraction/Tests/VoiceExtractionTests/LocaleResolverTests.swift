import XCTest
import VoiceExtraction

final class LocaleResolverTests: XCTestCase {

    private func bcp47(_ id: String) -> String { Locale(identifier: id).identifier(.bcp47) }

    func testExactMatchWins() {
        let supported = [Locale(identifier: "en_US"), Locale(identifier: "es_MX")]
        let resolved = LocaleResolver.resolve(Locale(identifier: "en_US"), against: supported)
        XCTAssertEqual(resolved?.identifier(.bcp47), bcp47("en_US"))
    }

    /// The device finding: en_MX isn't shipped → resolve to en_US, not failure.
    func testEnglishFallsBackToUS() {
        let supported = [
            Locale(identifier: "en_GB"),
            Locale(identifier: "en_US"),
            Locale(identifier: "es_MX"),
        ]
        let resolved = LocaleResolver.resolve(Locale(identifier: "en_MX"), against: supported)
        XCTAssertEqual(resolved?.language.languageCode?.identifier, "en")
        XCTAssertEqual(resolved?.region?.identifier, "US")
    }

    func testSameLanguageWhenNoUSOption() {
        let supported = [Locale(identifier: "en_GB"), Locale(identifier: "es_MX")]
        let resolved = LocaleResolver.resolve(Locale(identifier: "en_AU"), against: supported)
        XCTAssertEqual(resolved?.region?.identifier, "GB")
    }

    func testNilWhenLanguageUnavailable() {
        let supported = [Locale(identifier: "es_MX"), Locale(identifier: "fr_FR")]
        XCTAssertNil(LocaleResolver.resolve(Locale(identifier: "de_DE"), against: supported))
    }

    func testNilWhenSupportedEmpty() {
        XCTAssertNil(LocaleResolver.resolve(Locale(identifier: "en_US"), against: []))
    }
}
