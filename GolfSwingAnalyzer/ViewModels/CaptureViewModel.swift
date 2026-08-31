import Combine
import Foundation

@MainActor
final class CaptureViewModel: ObservableObject {
    let cameraController = CameraController()
    private let countdown = SwingCountdown()

    @Published var isRecording = false
    @Published var recordedVideoURL: URL?
    @Published var errorMessage: String?
    @Published var secondsRemaining: Int?
    @Published var countdownDuration: Int = SwingCountdownPreference.duration {
        didSet { SwingCountdownPreference.duration = countdownDuration }
    }

    init() {
        cameraController.$isRecording.assign(to: &$isRecording)
        cameraController.$lastRecordingURL.compactMap { $0 }.assign(to: &$recordedVideoURL)
        cameraController.$setupError.compactMap { $0 }.assign(to: &$errorMessage)
    }

    func start() {
        cameraController.requestAccessAndConfigure()
    }

    /// The single record button's behavior depends on the current state:
    /// idle -> start the countdown, counting down -> cancel it, recording
    /// -> stop early (the countdown's own 10s window stops it otherwise).
    func primaryButtonTapped() {
        if isRecording {
            countdown.cancel()
            cameraController.stopRecording()
        } else if secondsRemaining != nil {
            countdown.cancel()
            secondsRemaining = nil
        } else {
            recordedVideoURL = nil
            countdown.start(
                duration: countdownDuration,
                onTick: { [weak self] value in self?.secondsRemaining = value },
                onGo: { [weak self] in self?.cameraController.startRecording() },
                onAutoStop: { [weak self] in self?.cameraController.stopRecording() }
            )
        }
    }
}
