import Combine
import Foundation

@MainActor
final class CalibrationViewModel: ObservableObject {
    enum Phase {
        case positioning
        case countingDown
        case recording
        case analyzing
        case passed
        case failed(String)
    }

    let cameraController = CameraController()
    private let countdown = SwingCountdown()

    @Published var phase: Phase = .positioning
    @Published var errorMessage: String?
    @Published var secondsRemaining: Int?
    @Published var countdownDuration: Int = SwingCountdownPreference.duration {
        didSet { SwingCountdownPreference.duration = countdownDuration }
    }

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
        phase = .countingDown
        countdown.start(
            duration: countdownDuration,
            onTick: { [weak self] value in self?.secondsRemaining = value },
            onGo: { [weak self] in
                self?.phase = .recording
                self?.cameraController.startRecording()
            },
            onAutoStop: { [weak self] in self?.finishPracticeSwing() }
        )
    }

    func cancelCountdown() {
        countdown.cancel()
        secondsRemaining = nil
        phase = .positioning
    }

    func finishPracticeSwing() {
        countdown.cancel()
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
