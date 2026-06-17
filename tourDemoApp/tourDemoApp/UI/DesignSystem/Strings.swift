//
//  Strings.swift
//  Design system — user-facing copy in one place.
//
//  Lane-1 stand-in for a `.xcstrings` catalog: no hardcoded text in a view, so
//  rewording or localizing touches only this file (iOS architecture §3.2).
//  Promote to a real String Catalog when a second locale appears.
//

enum Strings {
    enum App {
        static let name = "Tour Debrief"
    }

    enum Tabs {
        static let today = "Today"
        static let compare = "Compare"
        static let plan = "Plan"
    }

    enum Onboarding {
        // The shared eyebrow + serif title for the dark focus screens. Screens
        // compose `FocusHeader` (UI/Components) with these — no header wrapper.
        static let eyebrow = "ONBOARDING · VOICE PREFERENCES"
        static let title = "Tell me what you’re looking for."
    }

    enum Today {
        static let emptyTitle = "No listings yet"
        static let emptyMessage = "Once homes are added to the backend, they'll show up here."
        static let errorTitle = "Couldn't load listings"
        static let retry = "Try again"
    }

    enum Debrief {
        static let navTitle = "Debrief"
        // Recording screen (reuses the dark focus header).
        static let eyebrow = "DEBRIEF · VOICE IMPRESSION"
        static let recordTitle = "How did it feel?"
        // Confirmation screen.
        static let confirmEyebrow = "EXTRACTED · THIS HOME"
        static let confirmTitle = "Here’s what I heard."
        static let confirmSubtitle = "Toggle off anything that’s not right — only what you keep touches memory."
        static let profileChangesHeader = "CHANGES TO YOUR PROFILE"
        static let footer = "nothing commits until you save"
        // Complete screen.
        static let savedTitle = "Saved to this home"
        static let seeCompare = "See how Compare re-ranked"
        static let done = "Done"
        // Per-card entry on Today.
        static let record = "Record briefing"
        static let markToured = "Dev · mark toured"
    }

    enum Compare {
        static let title = "Nothing to compare yet"
        static let message = "Toured homes rank here by how well they fit your preferences — explained, not just listed. Tour a home and record a debrief to populate it."
        static let whyHeader = "WHY THIS ORDER"
        static let updated = "Updated from your debrief"
    }

    enum Plan {
        static let title = "No next step yet"
        static let message = "Once you've toured and debriefed, your best next action shows up here."
    }
}
