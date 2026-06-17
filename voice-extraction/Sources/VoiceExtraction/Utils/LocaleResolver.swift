import Foundation

/// Resolves a desired locale against the locales the transcriber actually
/// supports.
///
/// This is mandatory, not polish: a real test device reported `en_MX`
/// (English / Mexico region), which Apple ships no assets for — naively passing
/// `Locale.current` to `SpeechTranscriber` fails. A real user base hits mixed
/// language/region combos constantly, so we fall back to the same language.
///
/// Pure and deterministic, so it's unit-tested independently of any device.
public enum LocaleResolver {

    /// Resolve `desired` against `supported`:
    /// 1. exact bcp47 match, else
    /// 2. same language, preferring the US region for English, else
    /// 3. the first supported locale sharing the language, else
    /// 4. `nil` (no asset for this language at all).
    public static func resolve(_ desired: Locale, against supported: [Locale]) -> Locale? {
        if let exact = supported.first(where: { $0.identifier(.bcp47) == desired.identifier(.bcp47) }) {
            return exact
        }
        guard let language = desired.language.languageCode?.identifier else { return nil }
        let sameLanguage = supported.filter { $0.language.languageCode?.identifier == language }
        if language == "en", let us = sameLanguage.first(where: { $0.region?.identifier == "US" }) {
            return us
        }
        return sameLanguage.first
    }
}
