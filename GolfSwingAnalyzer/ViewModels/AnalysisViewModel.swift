import CoreMedia
import Foundation

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published private(set) var isAnalyzing = false
    @Published private(set) var session: SwingSession?
    @Published var errorMessage: String?

    private let poseExtractor: PoseProviding = VisionPoseExtractor()
    private let phaseDetector: SwingPhaseDetecting = HeuristicPhaseDetector()
    private let feedbackEngine = FeedbackEngine(rules: FaceOnCheckpoints.all)

    func analyze(videoURL: URL) {
        isAnalyzing = true
        errorMessage = nil
        Task {
            do {
                let frames = try await poseExtractor.extractPoseFrames(from: videoURL)
                guard !frames.isEmpty else {
                    errorMessage = "Couldn't detect a person in that video — make sure you're clearly visible, well-lit, and facing the camera."
                    isAnalyzing = false
                    return
                }
                let phases = phaseDetector.detectPhases(in: frames)
                var newSession = SwingSession(videoURL: videoURL, frames: frames, phases: phases)
                newSession.tips = feedbackEngine.evaluate(session: newSession)
                session = newSession
                Self.logSummary(newSession)
            } catch {
                errorMessage = "Analysis failed: \(error.localizedDescription)"
            }
            isAnalyzing = false
        }
    }

    func reset() {
        session = nil
        errorMessage = nil
    }

    /// Stands in for the results screen (Milestone 5/8, not built yet) so
    /// the pipeline is verifiable now: check Xcode's console after analysis.
    private static func logSummary(_ session: SwingSession) {
        print("=== Swing analysis complete ===")
        print("Frames analyzed: \(session.frames.count)")
        for phase in SwingPhase.allCases {
            if let index = session.phases[phase], session.frames.indices.contains(index) {
                let seconds = CMTimeGetSeconds(session.frames[index].timestamp)
                print("  \(phase.rawValue): frame \(index) (\(String(format: "%.2f", seconds))s)")
            } else {
                print("  \(phase.rawValue): not detected")
            }
        }
        if session.tips.isEmpty {
            print("Tips: none")
        } else {
            print("Tips:")
            for tip in session.tips {
                print("  [\(tip.phase.rawValue)] \(tip.message)")
            }
        }
        print("================================")
    }
}
