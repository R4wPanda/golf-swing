import AVKit
import SwiftUI

/// Minimal post-recording playback so a milestone-1 test can confirm the
/// clip came out upright. The scrubbable/overlaid player lives in Playback/,
/// added in a later milestone.
struct ReviewClipView: View {
    let url: URL
    let onDismiss: () -> Void

    @State private var player: AVPlayer

    init(url: URL, onDismiss: @escaping () -> Void) {
        self.url = url
        self.onDismiss = onDismiss
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        NavigationStack {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .onAppear { player.play() }
                .navigationTitle("Review Swing")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Retake", action: onDismiss)
                    }
                }
        }
    }
}
