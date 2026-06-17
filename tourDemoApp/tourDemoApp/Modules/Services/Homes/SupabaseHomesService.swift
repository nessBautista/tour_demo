//
//  SupabaseHomesService.swift
//  tourDemoApp — Modules/Services/Homes
//
//  Live listings, fetched from Supabase's auto-generated REST API (PostgREST) with
//  plain URLSession — Foundation only, no SDK dependency (the vanilla-Swift rule,
//  iOS architecture §1). This is exactly what the Supabase client does under the
//  hood: GET /rest/v1/listings with the anon key in `apikey` + `Authorization`.
//
//  The anon (RLS-scoped) key is the only credential here — never service_role.
//  Reads the `listings` table seeded by the backend (code/apps/tour_demo/backend).
//

import Foundation

struct SupabaseHomesService: HomesProviding {
    /// Bare project URL, e.g. https://<ref>.supabase.co (no trailing /rest/v1).
    let baseURL: URL
    let anonKey: String
    var session: URLSession = .shared

    func fetchHomes() async throws -> [Home] {
        let endpoint = baseURL.appendingPathComponent("rest/v1/listings")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw HomesError.badURL
        }
        components.queryItems = [
            URLQueryItem(name: "select", value: Home.selectedColumns),
            URLQueryItem(name: "order", value: "created_at.desc"),
        ]
        guard let url = components.url else { throw HomesError.badURL }

        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw HomesError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HomesError.server(status: http.statusCode,
                                    body: String(data: data, encoding: .utf8) ?? "")
        }

        do {
            return try JSONDecoder().decode([Home].self, from: data)
        } catch {
            throw HomesError.decoding(error)
        }
    }
}
