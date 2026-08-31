import SwiftUI

struct CaptureView: View {
    @StateObject private var viewModel = CaptureViewModel()

    var body: some View {
        ZStack {
            CameraPreviewView(previewLayer: viewModel.cameraController.makePreviewLayer())
                .ignoresSafeArea()

            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .padding(8)
                        .background(.black.opacity(0.6))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 24)
                }

                if let secondsRemaining = viewModel.secondsRemaining {
                    Spacer()
                    Text("\(secondsRemaining)")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 8)
                }

                Spacer()

                if viewModel.secondsRemaining == nil && !viewModel.isRecording {
                    durationPicker
                        .padding(.bottom, 12)
                }

                recordButton
                    .padding(.bottom, 32)
            }
        }
        .onAppear { viewModel.start() }
        .sheet(isPresented: isReviewPresented) {
            if let url = viewModel.recordedVideoURL {
                ReviewClipView(url: url) {
                    viewModel.recordedVideoURL = nil
                }
            }
        }
    }

    private var isReviewPresented: Binding<Bool> {
        Binding(
            get: { viewModel.recordedVideoURL != nil },
            set: { isPresented in
                if !isPresented { viewModel.recordedVideoURL = nil }
            }
        )
    }

    private var durationPicker: some View {
        Picker("Countdown", selection: $viewModel.countdownDuration) {
            Text("5s").tag(5)
            Text("10s").tag(10)
        }
        .pickerStyle(.segmented)
        .frame(width: 140)
        .background(.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var recordButton: some View {
        Button(action: viewModel.primaryButtonTapped) {
            Circle()
                .strokeBorder(.white, lineWidth: 4)
                .frame(width: 76, height: 76)
                .background(
                    Circle()
                        .fill(.red)
                        .frame(
                            width: viewModel.isRecording ? 32 : 64,
                            height: viewModel.isRecording ? 32 : 64
                        )
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
                )
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if viewModel.isRecording { return "Stop Recording" }
        if viewModel.secondsRemaining != nil { return "Cancel Countdown" }
        return "Start Recording"
    }
}
