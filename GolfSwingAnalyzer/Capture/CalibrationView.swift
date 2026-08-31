import SwiftUI

/// Gates the real swing recording behind a practice-swing framing check —
/// see the plan's "Amendment: portrait shell + framing calibration".
struct CalibrationView: View {
    @StateObject private var viewModel = CalibrationViewModel()
    let onCalibrated: () -> Void

    var body: some View {
        ZStack {
            CameraPreviewView(previewLayer: viewModel.cameraController.makePreviewLayer())
                .ignoresSafeArea()

            VStack {
                Spacer()
                statusPanel
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            OrientationLock.shared.allowsLandscape = true
            viewModel.start()
        }
        .onDisappear {
            OrientationLock.shared.allowsLandscape = false
        }
    }

    @ViewBuilder
    private var statusPanel: some View {
        VStack(spacing: 12) {
            switch viewModel.phase {
            case .positioning:
                Text("Do a practice swing so we can check your framing.")
                Button("Start Practice Swing") { viewModel.beginPracticeSwing() }
                    .buttonStyle(.borderedProminent)
            case .recording:
                Text("Recording — do your practice swing, then tap Done.")
                Button("Done") { viewModel.finishPracticeSwing() }
                    .buttonStyle(.borderedProminent)
            case .analyzing:
                ProgressView("Checking your framing…")
                    .tint(.white)
            case .passed:
                Text("Looks good!").bold()
                Button("Start Swing Recording", action: onCalibrated)
                    .buttonStyle(.borderedProminent)
            case .failed(let message):
                Text(message)
                    .multilineTextAlignment(.center)
                Button("Try Again") { viewModel.retry() }
                    .buttonStyle(.borderedProminent)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .foregroundStyle(.white)
        .background(.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
