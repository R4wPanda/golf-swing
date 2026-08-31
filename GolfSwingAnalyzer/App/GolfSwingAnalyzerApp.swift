import SwiftUI

@main
struct GolfSwingAnalyzerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RecordSwingFlowView()
        }
    }
}

/// Practice-swing framing calibration must pass before the real recording
/// screen is reachable — see CalibrationView.
private struct RecordSwingFlowView: View {
    @State private var isCalibrated = false

    var body: some View {
        if isCalibrated {
            CaptureView()
        } else {
            CalibrationView(onCalibrated: { isCalibrated = true })
        }
    }
}
