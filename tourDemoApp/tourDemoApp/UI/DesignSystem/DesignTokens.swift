//
//  DesignTokens.swift
//  tourDemoApp — UI/DesignSystem
//
//  The app's small design system, ported from TourDebrief. Values were extracted
//  from the product design ("Tour Debrief Companion.html"): brand colors authored
//  in oklch were converted to sRGB; the neutral ramp, type scale, radii and
//  spacing come straight from the design.
//
//  Screens reference these SEMANTIC tokens, never raw hex/points, so a restyle or
//  rebrand happens here (iOS architecture §3.2).
//

import SwiftUI

// MARK: - Colors (semantic tokens, resolved from the active Theme/Palette)
//
// Namespaced under `AppColor` (not an `extension Color`) on purpose: Xcode
// auto-generates `Color.<assetName>` symbols from catalogs, so extending Color
// with the same names would redeclare them. Each token is a COMPUTED accessor
// over `Theme.shared.palette`, so screens get one stable API
// (`AppColor.brandPrimary`) while the family (cold/warm) can switch live — every
// view reading a token re-renders on change. See Palette.swift.

enum AppColor {
    // Brand / accent
    static var brandPrimary: Color      { Theme.shared.palette.brandPrimary }
    static var brandPrimaryLight: Color { Theme.shared.palette.brandPrimaryLight }
    static var brandPrimaryDark: Color  { Theme.shared.palette.brandPrimaryDark }
    static var brandTint: Color         { Theme.shared.palette.brandTint }
    static var brandShadow: Color       { Theme.shared.palette.brandShadow }

    // Status
    static var success: Color     { Theme.shared.palette.success }
    static var successTint: Color { Theme.shared.palette.successTint }
    static var negative: Color     { Theme.shared.palette.negative }
    static var negativeTint: Color { Theme.shared.palette.negativeTint }
    static var highlight: Color   { Theme.shared.palette.highlight }

    // Text / ink
    static var textPrimary: Color   { Theme.shared.palette.textPrimary }
    static var textSecondary: Color { Theme.shared.palette.textSecondary }
    static var textMuted: Color     { Theme.shared.palette.textMuted }
    static var onAccent: Color      { Theme.shared.palette.onAccent }

    // Surfaces
    static var appBackground: Color { Theme.shared.palette.appBackground }
    static var surface: Color       { Theme.shared.palette.surface }
    static var surfaceSunken: Color { Theme.shared.palette.surfaceSunken }
    static var divider: Color       { Theme.shared.palette.divider }

    // Dark focus surfaces (recording / extraction)
    static var surfaceDark: Color        { Theme.shared.palette.surfaceDark }
    static var onSurfaceDark: Color       { Theme.shared.palette.onSurfaceDark }
    static var onSurfaceDarkMuted: Color  { Theme.shared.palette.onSurfaceDarkMuted }
}

// MARK: - Spacing (8-pt-ish scale from the design)

enum Spacing {
    static let xs: CGFloat = 4
    static let s:  CGFloat = 8
    static let m:  CGFloat = 12
    static let l:  CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner radii (from the design's border-radius set)

enum Radius {
    static let s:    CGFloat = 8
    static let m:    CGFloat = 12
    static let l:    CGFloat = 16
    static let xl:   CGFloat = 20
    static let xxl:  CGFloat = 28
    static let pill: CGFloat = 999
}

// MARK: - Typography
//
// Brand headings are a serif (the design uses 'Source Serif 4'); we map them to
// the system serif (New York) via `design: .serif` rather than bundling a font.
// Body/UI text is the system sans. Scale: 33/26/20/17/15/14/13/12/10.

enum Typography {
    static let display   = Font.system(size: 33, weight: .semibold, design: .serif) // hero screen titles
    static let heading   = Font.system(size: 26, weight: .semibold, design: .serif) // in-flow screen titles
    static let title     = Font.system(size: 20, weight: .semibold, design: .serif) // section titles
    static let serifBody = Font.system(size: 17, weight: .regular, design: .serif)  // transcript / prose
    static let bodyLarge = Font.system(size: 15, weight: .regular)
    static let body      = Font.system(size: 14, weight: .regular)
    static let subhead   = Font.system(size: 13, weight: .regular)
    static let caption   = Font.system(size: 12, weight: .regular)
    static let micro     = Font.system(size: 10, weight: .semibold)

    // Monospace — technical labels, tool calls, timers, footnotes.
    static let eyebrow   = Font.system(size: 11, weight: .semibold, design: .monospaced)
    static let mono      = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let monoSmall = Font.system(size: 11, weight: .regular, design: .monospaced)
}
