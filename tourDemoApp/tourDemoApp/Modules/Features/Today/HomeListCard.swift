//
//  HomeListCard.swift
//  tourDemoApp — Modules/Features/Today
//
//  One listing on the Today screen: a photo (async-loaded, with a placeholder),
//  address, price, and the bed/bath/sqft spec. Feature-specific, so it lives with
//  Today and is built from design tokens (iOS architecture §3.2). A dumb renderer
//  of a `Home` — no actions yet.
//

import SwiftUI

struct HomeListCard: View {
    let home: Home

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            photo
            details
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
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

#Preview {
    ScrollView {
        LazyVStack(spacing: Spacing.l) {
            ForEach(FixtureHomesService.demoHomes) { HomeListCard(home: $0) }
        }
        .padding()
    }
    .background(AppColor.appBackground)
}
