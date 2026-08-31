import AVFoundation

enum SwingCountdownPreference {
    private static let key = "swingCountdownDuration"

    static var duration: Int {
        get {
            let saved = UserDefaults.standard.integer(forKey: key)
            return saved == 10 ? 10 : 5
        }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

/// Drives the voice countdown before a swing recording and the fixed
/// recording window after it. Recording itself only starts once the
/// countdown reaches "go" — the countdown period isn't captured on video,
/// keeping clips short (less file size/processing, and fewer long gaps for
/// the phase-detection heuristic to trip over).
///
/// Deliberately holds no `@Published` state of its own — callers (view
/// models) own that directly via `onTick`, so a view observing the view
/// model re-renders correctly without also having to separately observe
/// this object.
@MainActor
final class SwingCountdown {
    static let recordingDuration: TimeInterval = 10

    private let synthesizer = AVSpeechSynthesizer()
    private var task: Task<Void, Never>?

    private static let voice: AVSpeechSynthesisVoice? = {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        return voices.first { $0.gender == .female && $0.language.hasPrefix("en") }
            ?? voices.first { $0.gender == .female }
    }()

    /// `onTick` reports the current countdown number, `nil` once cleared.
    /// `onGo` starts the actual recording; `onAutoStop` fires once the fixed
    /// recording window elapses (wire this to the same stop path a manual
    /// "Done" tap uses).
    func start(
        duration: Int,
        onTick: @escaping (Int?) -> Void,
        onGo: @escaping () -> Void,
        onAutoStop: @escaping () -> Void
    ) {
        task?.cancel()
        task = Task {
            for remaining in stride(from: duration, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                onTick(remaining)
                speak("\(remaining)")
                try? await Task.sleep(for: .seconds(1))
            }
            guard !Task.isCancelled else { return }
            onTick(0)
            speak("Hit the ball")
            onGo()

            try? await Task.sleep(for: .seconds(Self.recordingDuration))
            guard !Task.isCancelled else { return }
            onTick(nil)
            onAutoStop()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.voice
        synthesizer.speak(utterance)
    }
}
