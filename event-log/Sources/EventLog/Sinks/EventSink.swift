import Foundation

/// Where events go. The whole app codes against this seam (via ``EventLogger``)
/// and never against a concrete sink — so the destination (in-memory buffer,
/// console, later a Supabase writer) is swappable, and several can run at once.
///
/// `record` is synchronous and `Sendable`, so it's callable from anywhere —
/// the main actor, a background task, the agent loop — without `await`.
/// Implementations own their own thread-safety.
public protocol EventSink: Sendable {
    func record(_ event: Event)
}
