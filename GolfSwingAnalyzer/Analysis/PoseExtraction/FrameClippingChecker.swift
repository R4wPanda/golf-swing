import CoreGraphics

nonisolated enum FrameEdge {
    case top, bottom, left, right
}

struct ClippingCheckResult {
    let passed: Bool
    let clippedEdges: Set<FrameEdge>

    var guidanceMessage: String {
        guard !passed else { return "Looks good!" }
        if clippedEdges.contains(.top) || clippedEdges.contains(.bottom) {
            return "Part of your swing went above or below the frame. Step back so your full swing — including the club overhead — stays in view."
        }
        return "Part of your swing went off the side of the frame. Step back to give yourself more room on both sides."
    }
}

/// Checks whether any joint got clipped at the frame edge at any point in a
/// practice-swing clip. Deliberately simple for v1: it only answers
/// pass/fail plus a general "step back" direction — it doesn't try to
/// suggest moving closer when there's unused margin, since that's a
/// secondary quality nicety rather than something that breaks pose tracking.
enum FrameClippingChecker {
    nonisolated static let edgeMargin: CGFloat = 0.04
    nonisolated static let minJointConfidence: Float = 0.3

    nonisolated static func evaluate(frames: [PoseFrame]) -> ClippingCheckResult {
        var clippedEdges: Set<FrameEdge> = []

        for frame in frames {
            for sample in frame.joints.values where sample.confidence >= minJointConfidence {
                if sample.point.x <= edgeMargin { clippedEdges.insert(.left) }
                if sample.point.x >= 1 - edgeMargin { clippedEdges.insert(.right) }
                if sample.point.y <= edgeMargin { clippedEdges.insert(.bottom) }
                if sample.point.y >= 1 - edgeMargin { clippedEdges.insert(.top) }
            }
        }

        return ClippingCheckResult(passed: clippedEdges.isEmpty, clippedEdges: clippedEdges)
    }
}
