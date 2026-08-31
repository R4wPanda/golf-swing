protocol SwingPhaseDetecting {
    nonisolated func detectPhases(in frames: [PoseFrame]) -> [SwingPhase: Int]
}
