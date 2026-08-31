import SwiftUI

/// Practice-swing framing calibration must pass before the real recording
/// screen is reachable — see CalibrationView.
struct RecordSwingFlowView: View {
    @State private var isCalibrated = false

    var body: some View {
        if isCalibrated {
            CaptureView()
        } else {
            CalibrationView(onCalibrated: { isCalibrated = true })
        }
    }
}
