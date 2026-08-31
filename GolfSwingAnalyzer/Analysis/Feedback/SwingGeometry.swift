import CoreGraphics
import Vision

enum SwingGeometry {
    /// Angle in degrees of the line from `from` to `to`, measured from
    /// horizontal (0° = pointing along +x).
    static func lineAngleDegrees(from: CGPoint, to: CGPoint) -> CGFloat {
        atan2(to.y - from.y, to.x - from.x) * 180 / .pi
    }

    static func point(
        _ joint: VNHumanBodyPoseObservation.JointName,
        in frame: PoseFrame,
        minConfidence: Float = 0.3
    ) -> CGPoint? {
        guard let sample = frame.joints[joint], sample.confidence >= minConfidence else { return nil }
        return sample.point
    }

    static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}
