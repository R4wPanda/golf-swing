import CoreGraphics
import Vision

/// The v1 face-on checkpoint set from the plan. Every threshold here is a
/// teaching heuristic, not validated against real swing data — expect to
/// retune these after seeing real output (see the plan's per-checkpoint
/// confidence notes; several are explicitly "low confidence, loose sanity
/// check" rather than settled numbers).
enum FaceOnCheckpoints {
    static let all: [FeedbackRule] = [
        ShoulderLevelAtAddress(),
        ShoulderRotationAtTop(),
        HeadSwayAtTop(),
        HipRotationAtImpact(),
        HeadPositionAtImpact(),
        RotationToFinish(),
    ]
}

nonisolated private let headSwayThreshold: CGFloat = 0.12 // fraction of address shoulder width; plan estimates 10-15%

nonisolated private func shoulderWidthAtAddress(_ session: SwingSession) -> CGFloat? {
    guard let frame = session.frame(for: .address),
          let left = SwingGeometry.point(.leftShoulder, in: frame),
          let right = SwingGeometry.point(.rightShoulder, in: frame) else { return nil }
    return SwingGeometry.distance(left, right)
}

nonisolated private func headSway(in session: SwingSession, at phase: SwingPhase) -> CGFloat? {
    guard let addressFrame = session.frame(for: .address),
          let phaseFrame = session.frame(for: phase),
          let addressHead = SwingGeometry.point(.nose, in: addressFrame),
          let phaseHead = SwingGeometry.point(.nose, in: phaseFrame),
          let width = shoulderWidthAtAddress(session), width > 0 else { return nil }
    return abs(phaseHead.x - addressHead.x) / width
}

nonisolated private func lineAngle(
    _ a: VNHumanBodyPoseObservation.JointName,
    _ b: VNHumanBodyPoseObservation.JointName,
    in frame: PoseFrame
) -> CGFloat? {
    guard let pointA = SwingGeometry.point(a, in: frame), let pointB = SwingGeometry.point(b, in: frame) else { return nil }
    return SwingGeometry.lineAngleDegrees(from: pointA, to: pointB)
}

nonisolated private func rotation(
    _ joints: (VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName),
    in session: SwingSession,
    at phase: SwingPhase
) -> CGFloat? {
    guard let addressFrame = session.frame(for: .address),
          let phaseFrame = session.frame(for: phase),
          let addressAngle = lineAngle(joints.0, joints.1, in: addressFrame),
          let phaseAngle = lineAngle(joints.0, joints.1, in: phaseFrame) else { return nil }
    return abs(phaseAngle - addressAngle)
}

struct ShoulderLevelAtAddress: FeedbackRule {
    let checkpointID = "shoulderLevelAtAddress"
    let phase = SwingPhase.address

    nonisolated func evaluate(session: SwingSession) -> Tip? {
        guard let frame = session.frame(for: .address),
              let angle = lineAngle(.leftShoulder, .rightShoulder, in: frame),
              abs(angle) > 15 else { return nil }
        return Tip(
            checkpointID: checkpointID,
            phase: phase,
            message: "Your shoulders look noticeably tilted at address — a slight tilt away from the target is normal, but check your setup isn't overly angled.",
            severity: .suggestion
        )
    }
}

struct ShoulderRotationAtTop: FeedbackRule {
    let checkpointID = "shoulderRotationAtTop"
    let phase = SwingPhase.top

    nonisolated func evaluate(session: SwingSession) -> Tip? {
        guard let rotationAmount = rotation((.leftShoulder, .rightShoulder), in: session, at: .top),
              rotationAmount < 60 else { return nil }
        return Tip(
            checkpointID: checkpointID,
            phase: phase,
            message: "Your shoulder turn at the top looks limited — a fuller shoulder rotation (roughly 80–90°) usually adds power and consistency.",
            severity: .suggestion
        )
    }
}

struct HeadSwayAtTop: FeedbackRule {
    let checkpointID = "headSwayAtTop"
    let phase = SwingPhase.top

    nonisolated func evaluate(session: SwingSession) -> Tip? {
        guard let sway = headSway(in: session, at: .top), sway > headSwayThreshold else { return nil }
        return Tip(
            checkpointID: checkpointID,
            phase: phase,
            message: "Your head moved noticeably off the ball at the top of your backswing — try keeping it steadier through the takeaway.",
            severity: .suggestion
        )
    }
}

struct HipRotationAtImpact: FeedbackRule {
    let checkpointID = "hipRotationAtImpact"
    let phase = SwingPhase.impact

    nonisolated func evaluate(session: SwingSession) -> Tip? {
        guard let rotationAmount = rotation((.leftHip, .rightHip), in: session, at: .impact),
              rotationAmount < 20 else { return nil }
        return Tip(
            checkpointID: checkpointID,
            phase: phase,
            message: "Your hips look fairly closed at impact — rotating them more toward the target through impact usually helps you get through the ball.",
            severity: .suggestion
        )
    }
}

struct HeadPositionAtImpact: FeedbackRule {
    let checkpointID = "headPositionAtImpact"
    let phase = SwingPhase.impact

    nonisolated func evaluate(session: SwingSession) -> Tip? {
        guard let sway = headSway(in: session, at: .impact), sway > headSwayThreshold else { return nil }
        return Tip(
            checkpointID: checkpointID,
            phase: phase,
            message: "Your head has drifted noticeably from its address position by impact — try to keep it more centered over the ball.",
            severity: .suggestion
        )
    }
}

struct RotationToFinish: FeedbackRule {
    let checkpointID = "rotationToFinish"
    let phase = SwingPhase.followThrough

    nonisolated func evaluate(session: SwingSession) -> Tip? {
        guard let rotationAmount = rotation((.leftShoulder, .rightShoulder), in: session, at: .followThrough),
              rotationAmount < 45 else { return nil }
        return Tip(
            checkpointID: checkpointID,
            phase: phase,
            message: "Your finish position looks like it stalls short of fully facing the target — rotating all the way through to a balanced finish is worth working on.",
            severity: .info
        )
    }
}
