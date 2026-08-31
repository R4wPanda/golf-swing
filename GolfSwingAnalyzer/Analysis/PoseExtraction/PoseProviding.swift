import Foundation

/// The seam that keeps everything downstream (calibration, phase detection,
/// feedback, overlay) decoupled from Vision specifically — a future Core ML
/// or sensor-augmented extractor conforms to the same protocol.
protocol PoseProviding {
    nonisolated func extractPoseFrames(from url: URL) async throws -> [PoseFrame]
}
