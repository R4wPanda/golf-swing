import Combine
import Foundation

@MainActor
final class CalibrationViewModel: ObservableObject {
    enum Phase {
        case positioning
        case recording
        case analyzing
        case passed
        case failed(String)
    }

    let cameraController = CameraController()

    @Published var phase: Phase = .positioning
    @Published var errorMessage: String?

    private let poseExtractor: PoseProviding = VisionPoseExtractor()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        cameraController.$setupError.compactMap { $0 }.assign(to: &$errorMessage)
        cameraController.$lastRecordingURL.compactMap { $0 }
            .sink { [weak self] url in self?.analyze(url: url) }
            .store(in: &cancellables)
    }

    func start() {
        cameraController.requestAccessAndConfigure()
    }

    func beginPracticeSwing() {
        phase = .recording
        cameraController.startRecording()
    }

    func finishPracticeSwing() {
        phase = .analyzing
        cameraController.stopRecording()
    }

    func retry() {
        phase = .positioning
    }

    private func analyze(url: URL) {
        Task {
            do {
                let frames = try await poseExtractor.extractPoseFrames(from: url)
                let result = FrameClippingChecker.evaluate(frames: frames)
                phase = result.passed ? .passed : .failed(result.guidanceMessage)
            } catch {
                phase = .failed("Couldn't analyze that clip: \(error.localizedDescription)")
            }
        }
    }
}
