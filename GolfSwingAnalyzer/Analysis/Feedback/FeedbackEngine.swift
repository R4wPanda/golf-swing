struct FeedbackEngine {
    let rules: [FeedbackRule]

    nonisolated func evaluate(session: SwingSession) -> [Tip] {
        rules.compactMap { $0.evaluate(session: session) }
    }
}
