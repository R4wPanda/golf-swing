import AVFoundation
import Vision

/// Pulls frames straight from the video file via `AVAssetReader` (much
/// faster than a live `AVPlayer`/`AVCaptureVideoDataOutput` pipeline for
/// "record, then analyze") and runs `VNDetectHumanBodyPoseRequest` per frame.
/// `nonisolated` throughout so this runs on a background thread rather than
/// the main actor the project defaults new declarations to.
final class VisionPoseExtractor: PoseProviding {
    enum ExtractionError: Error {
        case noVideoTrack
        case readerFailed
    }

    private static let minJointConfidenceForSubjectSelection: Float = 0.3

    nonisolated func extractPoseFrames(from url: URL) async throws -> [PoseFrame] {
        let asset = AVURLAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw ExtractionError.noVideoTrack
        }
        let transform = try await track.load(.preferredTransform)
        let orientation = Self.cgOrientation(for: transform)
        print("[VisionPoseExtractor] preferredTransform=\(transform) -> orientation=\(orientation)")

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        reader.add(output)
        guard reader.startReading() else {
            throw ExtractionError.readerFailed
        }

        var frames: [PoseFrame] = []
        var rawFrameCount = 0
        let requestHandler = VNSequenceRequestHandler()

        while let sampleBuffer = output.copyNextSampleBuffer() {
            rawFrameCount += 1
            try autoreleasepool {
                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

                let request = VNDetectHumanBodyPoseRequest()
                try requestHandler.perform([request], on: pixelBuffer, orientation: orientation)

                guard let observation = Self.primarySubject(in: request.results) else { return }
                frames.append(PoseFrame(timestamp: timestamp, joints: Self.joints(from: observation)))
            }
        }

        print("[VisionPoseExtractor] read \(rawFrameCount) raw frame(s), detected a body in \(frames.count) of them")
        if reader.status == .failed {
            print("[VisionPoseExtractor] reader failed: \(String(describing: reader.error))")
        }

        return frames
    }

    /// Tolerant of minor floating-point noise in the transform components
    /// (rounds before comparing) rather than requiring an exact match against
    /// the four canonical rotation matrices.
    private static func cgOrientation(for transform: CGAffineTransform) -> CGImagePropertyOrientation {
        switch (transform.a.rounded(), transform.b.rounded(), transform.c.rounded(), transform.d.rounded()) {
        case (0, 1, -1, 0): return .right
        case (0, -1, 1, 0): return .left
        case (-1, 0, 0, -1): return .down
        default: return .up
        }
    }

    /// `VNDetectHumanBodyPoseRequest` can return one observation per detected
    /// person; pick whichever has the most confidently-recognized joints as a
    /// simple proxy for "the actual subject" in the expected single-person shot.
    private static func primarySubject(in observations: [VNHumanBodyPoseObservation]?) -> VNHumanBodyPoseObservation? {
        observations?.max { lhs, rhs in
            confidentJointCount(lhs) < confidentJointCount(rhs)
        }
    }

    private static func confidentJointCount(_ observation: VNHumanBodyPoseObservation) -> Int {
        let points = (try? observation.recognizedPoints(.all)) ?? [:]
        return points.values.filter { $0.confidence >= minJointConfidenceForSubjectSelection }.count
    }

    private static func joints(from observation: VNHumanBodyPoseObservation) -> [VNHumanBodyPoseObservation.JointName: JointSample] {
        let points = (try? observation.recognizedPoints(.all)) ?? [:]
        return points.mapValues { JointSample(point: $0.location, confidence: $0.confidence) }
    }
}
