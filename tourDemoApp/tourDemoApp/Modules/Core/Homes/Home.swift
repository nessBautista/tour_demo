//
//  Home.swift
//  tourDemoApp — Modules/Core/Homes
//
//  A house listing, as pure data. Core tier: Foundation-only value type, zero app
//  or UI knowledge (iOS architecture §3.1). Mirrors the backend `listings` table
//  (code/apps/tour_demo/backend) — the columns Today needs, decoded explicitly.
//
//  Explicit CodingKeys over .convertFromSnakeCase (predictable, no edge cases),
//  and we select only the columns declared here — the jsonb `facts` column and
//  `created_at` (timestamptz decoding gotchas) stay out of Today's blast radius.
//

import Foundation

struct Home: Identifiable, Equatable, Sendable, Codable {
    let id: UUID
    let address: String
    let price: Int
    let beds: Int
    let baths: Double
    let sqft: Int?
    let headline: String?
    let imageURL: URL?
    /// 0–100 per scored dimension (yard/commute/quiet/kitchen/light/parking), from
    /// the backend `ratings` jsonb. The scorer's input; string keys map to the
    /// closed `HomeDimension` vocabulary when ranking.
    let ratings: [String: Int]

    enum CodingKeys: String, CodingKey {
        case id, address, price, beds, baths, sqft, headline, ratings
        case imageURL = "image_url"
    }

    /// The PostgREST `select` list — exactly the fields above.
    static let selectedColumns = "id,address,price,beds,baths,sqft,headline,ratings,image_url"
}
