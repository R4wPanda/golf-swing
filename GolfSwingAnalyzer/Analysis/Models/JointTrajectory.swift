import Vision

extension Array where Element == PoseFrame {
    /// A joint's path across all frames where it was detected with at least
    /// `minConfidence` confidence — a derived view over `PoseFrame`s rather
    /// than a separately stored structure, per the plan.
    func trajectory(
        for joint: VNHumanBodyPoseObservation.JointName,
        minConfidence: Float = 0.3
    ) -> [(index: Int, sample: JointSample)] {
        enumerated().compactMap { index, frame in
            guard let sample = frame.joints[joint], sample.confidence >= minConfidence else { return nil }
            return (index, sample)
        }
    }
}
