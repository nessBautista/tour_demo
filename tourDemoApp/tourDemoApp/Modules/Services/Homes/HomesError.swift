//
//  HomesError.swift
//  tourDemoApp — Modules/Services/Homes
//
//  Failures the listings service can surface, with buyer-readable messages for
//  the Today error state.
//

import Foundation

enum HomesError: LocalizedError {
    case badURL
    case invalidResponse
    case server(status: Int, body: String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Could not build the listings request."
        case .invalidResponse:
            return "Unexpected response from the server."
        case .server(let status, _):
            return "The server returned an error (status \(status))."
        case .decoding:
            return "Could not read the listings data."
        }
    }
}
