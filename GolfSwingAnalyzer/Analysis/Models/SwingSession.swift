import Foundation

struct SwingSession {
    let videoURL: URL
    let frames: [PoseFrame]
    var phases: [SwingPhase: Int] = [:]
    var tips: [Tip] = []

    func frame(for phase: SwingPhase) -> PoseFrame? {
        guard let index = phases[phase], frames.indices.contains(index) else { return nil }
        return frames[index]
    }
}
