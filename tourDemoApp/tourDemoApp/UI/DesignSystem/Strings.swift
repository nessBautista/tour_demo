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
        static let title = "Tell us what you want"
        static let message = "Before your first tour, share what matters in a home. Voice capture lands here next."
        static let cta = "Get started"
    }

    enum Today {
        static let title = "Your homes"
        static let message = "Listings and tour status will show here. Book a tour, then debrief after you visit."
        static let openDebrief = "Open a debrief"
    }

    enum Debrief {
        static let navTitle = "Debrief"
        static let title = "Record your impression"
        static let message = "A 20–30s voice note after a tour becomes structured memory. Recording arrives with the debrief feature."
    }

    enum Compare {
        static let title = "Nothing to compare yet"
        static let message = "Toured homes will rank here by how well they fit your preferences — explained, not just listed."
    }

    enum Plan {
        static let title = "No next step yet"
        static let message = "Once you've toured and debriefed, your best next action shows up here."
    }
}
