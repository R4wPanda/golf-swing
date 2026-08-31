import AVKit
import SwiftUI

/// Post-recording playback with an "Analyze Swing" action that runs the
/// full pipeline (pose extraction -> phase detection -> feedback rules).
/// Results are shown inline as a simple summary for now — the scrubbable
/// overlay/results screen is a later milestone.
struct ReviewClipView: View {
    let url: URL
    let onRetake: () -> Void

    @StateObject private var analysisViewModel = AnalysisViewModel()
    @State private var player: AVPlayer

    init(url: URL, onRetake: @escaping () -> Void) {
        self.url = url
        self.onRetake = onRetake
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear { player.play() }

                statusPanel
                    .padding()
            }
            .navigationTitle("Review Swing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Retake", action: onRetake)
                }
            }
        }
    }

    @ViewBuilder
    private var statusPanel: some View {
        VStack(spacing: 8) {
            if analysisViewModel.isAnalyzing {
                ProgressView("Analyzing swing…")
                    .tint(.white)
            } else if let session = analysisViewModel.session {
                Text("Analysis complete — \(session.tips.count) tip(s) found.")
                Text("See Xcode console for details.")
                    .font(.footnote)
            } else {
                Button("Analyze Swing") { analysisViewModel.analyze(videoURL: url) }
                    .buttonStyle(.borderedProminent)
            }
            if let errorMessage = analysisViewModel.errorMessage {
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
