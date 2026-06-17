//
//  HomeListCard.swift
//  tourDemoApp — UI/Components
//
//  A listing card: photo (async-loaded, with a placeholder), address, price, and
//  the bed/bath/sqft spec. A pure renderer of the Core `Home` value type — no
//  feature copy, no state — so it's reusable across screens (Today now, Compare
//  later) and lives in the design system. UI may depend on Core (architecture §3.2).
//

import Foundation
import SwiftUI

struct HomeListCard: View {
    let home: Home
    /// Optional fit-against-profile (0–100), shown as a badge when present.
    var fitPercent: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            photo
            details
        }
        .overlay(alignment: .topTrailing) { fitBadge }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var fitBadge: some View {
        if let fitPercent {
            Text("\(fitPercent)% fit")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColor.onAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppColor.brandPrimary, in: Capsule())
                .padding(10)
        }
    }

    // MARK: Photo

    private var photo: some View {
        ZStack {
            AppColor.surfaceSunken
            if let url = home.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        ProgressView()
                    case .failure:
                        placeholderIcon
                    @unknown default:
                        placeholderIcon
                    }
                }
            } else {
                placeholderIcon
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .clipped()
    }

    private var placeholderIcon: some View {
        Image(systemName: "house.fill")
            .font(.system(size: 36, weight: .regular))
            .foregroundStyle(AppColor.textMuted)
    }

    // MARK: Details

    private var details: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(home.address)
                    .font(Typography.title)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer(minLength: Spacing.s)
                Text(priceText)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColor.textPrimary)
            }

            Text(specText)
                .font(Typography.subhead)
                .foregroundStyle(AppColor.textSecondary)

            if let headline = home.headline {
                Text(headline)
                    .font(Typography.subhead)
                    .foregroundStyle(AppColor.textMuted)
            }
        }
        .padding(Spacing.l)
    }

    // MARK: Formatting

    private var priceText: String {
        home.price.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private var specText: String {
        let bathText = home.baths.formatted(.number.precision(.fractionLength(0...1)))
        var parts = ["\(home.beds) bd", "\(bathText) ba"]
        if let sqft = home.sqft {
            parts.append("\(sqft.formatted()) sqft")
        }
        return parts.joined(separator: "  ·  ")
    }
}

// Preview-only sample data — inline `Home` (Core) values, so this UI component
// never reaches into a Service.
private let previewHomes: [Home] = [
    Home(id: UUID(), address: "412 Alder Court, Maple Grove", price: 485_000,
         beds: 3, baths: 2, sqft: 1_840,
         headline: "Sun-drenched corner lot with a big yard", imageURL: nil, ratings: [:]),
    Home(id: UUID(), address: "1735 Bellview Avenue, Old Town", price: 449_000,
         beds: 4, baths: 1.5, sqft: 1_820,
         headline: "Character craftsman on a quiet street", imageURL: nil, ratings: [:]),
]

#Preview {
    ScrollView {
        LazyVStack(spacing: Spacing.l) {
            ForEach(Array(previewHomes.enumerated()), id: \.offset) { i, home in
                HomeListCard(home: home, fitPercent: i == 0 ? 87 : 64)
            }
        }
        .padding()
    }
    .background(AppColor.appBackground)
}
