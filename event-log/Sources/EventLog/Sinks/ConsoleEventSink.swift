import Foundation

/// Prints each event as a readable line — for development. Stateless, so trivially
/// `Sendable`.
public struct ConsoleEventSink: EventSink {
    public init() {}

    public func record(_ event: Event) {
        print(Self.format(event))
    }

    static func format(_ event: Event) -> String {
        var parts = ["[\(event.category.rawValue)] \(event.name)"]
        if let m = event.inference {
            parts.append(
                "model=\(m.model) in=\(m.inputTokens) out=\(m.outputTokens) "
                + "\(m.latencyMS)ms\(m.succeeded ? "" : " FAILED")"
            )
        }
        if !event.properties.isEmpty {
            let props = event.properties
                .sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            parts.append(props)
        }
        return parts.joined(separator: "  ")
    }
}
