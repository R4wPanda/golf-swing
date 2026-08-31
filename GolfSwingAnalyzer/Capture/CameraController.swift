import AVFoundation
import Combine

/// Owns the AVCaptureSession: back-camera input locked to 60fps, no audio
/// (not needed for pose analysis, and it avoids a microphone permission
/// prompt), movie file output, and iOS 17 RotationCoordinator-based
/// orientation handling so the recorded clip is upright regardless of which
/// landscape orientation the device is physically held in.
final class CameraController: NSObject, ObservableObject {

    @Published private(set) var isRecording = false
    @Published private(set) var lastRecordingURL: URL?
    @Published var setupError: String?

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.golfswinganalyzer.session")
    private let movieOutput = AVCaptureMovieFileOutput()
    private var videoDevice: AVCaptureDevice?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private static let targetFrameRate = 60.0

    deinit {
        let session = session
        let queue = sessionQueue
        queue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func requestAccessAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            sessionQueue.async { self.configureSession() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.sessionQueue.async { self.configureSession() }
                } else {
                    DispatchQueue.main.async { self.setupError = "Camera access denied." }
                }
            }
        default:
            DispatchQueue.main.async {
                self.setupError = "Camera access denied. Enable it in Settings to record a swing."
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            DispatchQueue.main.async { self.setupError = "Unable to access the back camera." }
            return
        }
        session.addInput(input)
        videoDevice = device

        guard session.canAddOutput(movieOutput) else {
            session.commitConfiguration()
            DispatchQueue.main.async { self.setupError = "Unable to configure video output." }
            return
        }
        session.addOutput(movieOutput)

        configureFrameRate(for: device)

        // startRunning() must not be called until the configuration block is
        // committed — calling it while still "open" leaves the session in an
        // inconsistent state that crashes shortly after the first frame.
        session.commitConfiguration()
        session.startRunning()

        DispatchQueue.main.async { self.setUpRotationCoordinatorIfNeeded() }
    }

    private func configureFrameRate(for device: AVCaptureDevice) {
        let bestFormat = device.formats.first { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let supportsRate = format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= Self.targetFrameRate }
            return dimensions.height == 1080 && supportsRate
        }
        guard let format = bestFormat else { return }

        do {
            try device.lockForConfiguration()
            device.activeFormat = format
            let duration = CMTime(value: 1, timescale: Int32(Self.targetFrameRate))
            device.activeVideoMinFrameDuration = duration
            device.activeVideoMaxFrameDuration = duration
            device.unlockForConfiguration()
        } catch {
            DispatchQueue.main.async {
                self.setupError = "Couldn't set 60fps capture: \(error.localizedDescription)"
            }
        }
    }

    /// Returns the same preview layer instance on every call (SwiftUI's
    /// `body` re-evaluates often, and recreating the layer/RotationCoordinator
    /// on every render is both wasteful and unsafe).
    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        if let previewLayer {
            return previewLayer
        }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer
        setUpRotationCoordinatorIfNeeded()
        return layer
    }

    /// Wires up rotation handling once both the preview layer and the video
    /// device are known; whichever of the two becomes available last is
    /// responsible for calling this.
    private func setUpRotationCoordinatorIfNeeded() {
        guard rotationCoordinator == nil, let device = videoDevice, let layer = previewLayer else { return }

        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: layer)
        rotationCoordinator = coordinator
        applyRotation(angle: coordinator.videoRotationAngleForHorizonLevelPreview, to: layer.connection)
        rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.new]) { [weak self, weak layer] coordinator, _ in
            guard let layer else { return }
            self?.applyRotation(angle: coordinator.videoRotationAngleForHorizonLevelPreview, to: layer.connection)
        }
    }

    private func applyRotation(angle: CGFloat, to connection: AVCaptureConnection?) {
        guard let connection, connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }

    func startRecording() {
        sessionQueue.async {
            guard !self.movieOutput.isRecording else { return }

            if let coordinator = self.rotationCoordinator,
               let connection = self.movieOutput.connection(with: .video) {
                self.applyRotation(angle: coordinator.videoRotationAngleForHorizonLevelCapture, to: connection)
            }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
    }

    func stopRecording() {
        sessionQueue.async {
            self.movieOutput.stopRecording()
        }
    }
}

extension CameraController: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async { self.isRecording = true }
    }

    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            if let error {
                self.setupError = "Recording failed: \(error.localizedDescription)"
                return
            }
            self.lastRecordingURL = outputFileURL
        }
    }
}
