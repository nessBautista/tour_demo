//
//  Palette.swift
//  tourDemoApp — UI/DesignSystem
//
//  Ported from the TourDebrief design system. Two color families, switchable at
//  runtime from the Developer Tools overlay (shake to open, DEBUG):
//   • `cold` — Zillow×BEHR "cool & neutral": Zillow blue #0041D9 + black #111116,
//     with navy / platinum / polar-bear neutrals. **The default for this demo.**
//   • `warm` — the original terracotta/cream design (backed by DesignSystem.xcassets).
//
//  `Theme` holds the active family (default `.cold`). It's @Observable, so any view
//  reading an `AppColor` token re-renders when the palette changes.
//

import SwiftUI

struct Palette {
    let brandPrimary: Color
    let brandPrimaryLight: Color
    let brandPrimaryDark: Color
    let brandTint: Color
    let success: Color
    let successTint: Color
    let negative: Color
    let negativeTint: Color
    let highlight: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let onAccent: Color
    let appBackground: Color
    let surface: Color
    let surfaceSunken: Color
    let divider: Color

    // Dark "focus" surfaces — the recording / extraction screens invert to a
    // deep background with light text (brand accent stays the same).
    let surfaceDark: Color
    let onSurfaceDark: Color
    let onSurfaceDarkMuted: Color

    /// Colored drop shadow derived from the brand color.
    var brandShadow: Color { brandPrimary.opacity(0.4) }
}

extension Palette {
    /// Cold family — Zillow (#0041D9 / #111116) + BEHR "cool & neutral" tones
    /// (Very Navy, Sojourn Blue, Platinum, Polar Bear). The demo default.
    static let cold = Palette(
        brandPrimary:      Color(hex: 0x0041D9), // Zillow blue
        brandPrimaryLight: Color(hex: 0x4F74E8),
        brandPrimaryDark:  Color(hex: 0x00309F),
        brandTint:         Color(hex: 0xDEE7FB),
        success:           Color(hex: 0x1E8A5F),
        successTint:       Color(hex: 0xD6F0E4),
        negative:          Color(hex: 0xC44536), // red
        negativeTint:      Color(hex: 0xF4D9D4),
        highlight:         Color(hex: 0xFF6F61), // coral — Zillow's warm complement
        textPrimary:       Color(hex: 0x111116), // Zillow black
        textSecondary:     Color(hex: 0x2C3A47), // BEHR Very Navy
        textMuted:         Color(hex: 0x6E7B86), // BEHR Sojourn-ish gray
        onAccent:          Color(hex: 0xFFFFFF),
        appBackground:     Color(hex: 0xECEFF1), // cool off-white
        surface:           Color(hex: 0xF8FAFB),
        surfaceSunken:     Color(hex: 0xDFE5E9), // BEHR Platinum-ish
        divider:           Color(hex: 0xD2D8DC),
        surfaceDark:        Color(hex: 0x111116), // Zillow black
        onSurfaceDark:      Color(hex: 0xECEFF1),
        onSurfaceDarkMuted: Color(hex: 0x8A97A2)
    )

    /// Warm family — backed by DesignSystem.xcassets (the original design).
    static let warm = Palette(
        brandPrimary:      Color("AccentPrimary",      bundle: .main),
        brandPrimaryLight: Color("AccentPrimaryLight", bundle: .main),
        brandPrimaryDark:  Color("AccentPrimaryDark",  bundle: .main),
        brandTint:         Color("AccentTint",         bundle: .main),
        success:           Color("Success",            bundle: .main),
        successTint:       Color("SuccessTint",        bundle: .main),
        negative:          Color(hex: 0xB65C3F),       // coral-red (inline)
        negativeTint:      Color(hex: 0xF6DDD2),
        highlight:         Color("Highlight",          bundle: .main),
        textPrimary:       Color("TextPrimary",        bundle: .main),
        textSecondary:     Color("TextSecondary",      bundle: .main),
        textMuted:         Color("TextMuted",          bundle: .main),
        onAccent:          Color("OnAccent",           bundle: .main),
        appBackground:     Color("Background",         bundle: .main),
        surface:           Color("Surface",            bundle: .main),
        surfaceSunken:     Color("SurfaceSunken",      bundle: .main),
        divider:           Color("Divider",            bundle: .main),
        // Dark focus surfaces (inline — not part of the original light catalog).
        surfaceDark:        Color(hex: 0x1B1611),
        onSurfaceDark:      Color(hex: 0xF4EFE6),
        onSurfaceDarkMuted: Color(hex: 0x9A9082)
    )
}

enum PaletteKind: String, CaseIterable, Identifiable {
    case cold, warm
    var id: String { rawValue }
    var label: String { self == .warm ? "Warm" : "Cold" }
    var palette: Palette { self == .warm ? .warm : .cold }
}

@Observable
final class Theme {
    static let shared = Theme()
    var kind: PaletteKind = .cold
    var palette: Palette { kind.palette }
    private init() {}
}

extension Color {
    /// 0xRRGGBB convenience (sRGB, opaque).
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
