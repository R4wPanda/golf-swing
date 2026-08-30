import Combine
import Foundation

final class CaptureViewModel: ObservableObject {
    let cameraController = CameraController()

    @Published var isRecording = false
    @Published var recordedVideoURL: URL?
    @Published var errorMessage: String?

    init() {
        cameraController.$isRecording.assign(to: &$isRecording)
        cameraController.$lastRecordingURL.compactMap { $0 }.assign(to: &$recordedVideoURL)
        cameraController.$setupError.compactMap { $0 }.assign(to: &$errorMessage)
    }

    func start() {
        cameraController.requestAccessAndConfigure()
    }

    func toggleRecording() {
        if isRecording {
            cameraController.stopRecording()
        } else {
            recordedVideoURL = nil
            cameraController.startRecording()
        }
    }
}
