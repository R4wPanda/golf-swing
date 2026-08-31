import CoreGraphics
import CoreMedia
import Vision

/// One joint's detected position for a single frame. `point` is in Vision's
/// normalized coordinate space: (0,0) is the bottom-left corner, (1,1) the
/// top-right — the opposite vertical convention from UIKit/SwiftUI.
struct JointSample {
    let point: CGPoint
    let confidence: Float
}

struct PoseFrame {
    let timestamp: CMTime
    let joints: [VNHumanBodyPoseObservation.JointName: JointSample]
}
