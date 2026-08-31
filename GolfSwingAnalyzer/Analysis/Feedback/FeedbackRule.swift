protocol FeedbackRule: Sendable {
    var checkpointID: String { get }
    var phase: SwingPhase { get }
    nonisolated func evaluate(session: SwingSession) -> Tip?
}
