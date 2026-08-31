import CoreGraphics
import Vision

/// Detects swing phases from wrist height/velocity extrema, averaging both
/// wrists so this doesn't need to know player handedness. Deliberately
/// simple per the plan ("doesn't need to be perfect... reasonable for a
/// clean, well-framed swing") — every threshold here is a provisional
/// starting point to retune against real swings, not a validated value.
struct HeuristicPhaseDetector: SwingPhaseDetecting {
    private static let minConfidence: Float = 0.3
    /// Fraction of peak speed that counts as "started moving," for takeaway.
    private static let takeawaySpeedFraction: CGFloat = 0.1
    /// How far into the clip to search for a stable address position.
    private static let addressSearchFraction: CGFloat = 0.25

    nonisolated func detectPhases(in frames: [PoseFrame]) -> [SwingPhase: Int] {
        guard frames.count > 4 else { return [:] }

        let heights = frames.map { averagedWristPoint($0)?.y }
        let speeds = speeds(from: frames)

        guard let impactIndex = argmax(speeds) else { return [:] }

        let addressIndex = detectAddress(speeds: speeds)
        let topIndex = argmax(heights, from: addressIndex, upTo: impactIndex) ?? addressIndex
        let takeawayIndex = detectTakeaway(speeds: speeds, from: addressIndex, to: topIndex) ?? addressIndex
        let downswingIndex = (topIndex + impactIndex) / 2
        let followThroughIndex = argmax(heights, from: impactIndex, upTo: heights.count) ?? (heights.count - 1)

        return [
            .address: addressIndex,
            .takeaway: takeawayIndex,
            .top: topIndex,
            .downswing: downswingIndex,
            .impact: impactIndex,
            .followThrough: followThroughIndex,
        ]
    }

    // MARK: - Signal extraction

    private func averagedWristPoint(_ frame: PoseFrame) -> CGPoint? {
        let left = frame.joints[.leftWrist].flatMap { $0.confidence >= Self.minConfidence ? $0.point : nil }
        let right = frame.joints[.rightWrist].flatMap { $0.confidence >= Self.minConfidence ? $0.point : nil }
        switch (left, right) {
        case let (l?, r?): return CGPoint(x: (l.x + r.x) / 2, y: (l.y + r.y) / 2)
        case let (l?, nil): return l
        case let (nil, r?): return r
        default: return nil
        }
    }

    private func speeds(from frames: [PoseFrame]) -> [CGFloat?] {
        var result: [CGFloat?] = [nil]
        var previous = averagedWristPoint(frames[0])
        for frame in frames.dropFirst() {
            let current = averagedWristPoint(frame)
            if let current, let previous {
                let dx = current.x - previous.x
                let dy = current.y - previous.y
                result.append((dx * dx + dy * dy).squareRoot())
            } else {
                result.append(nil)
            }
            previous = current
        }
        return result
    }

    // MARK: - Phase heuristics

    private func detectAddress(speeds: [CGFloat?]) -> Int {
        let searchEnd = max(1, Int(CGFloat(speeds.count) * Self.addressSearchFraction))
        let peakSpeed = speeds.compactMap { $0 }.max() ?? 0
        let stableThreshold = peakSpeed * 0.05
        for index in 0..<searchEnd where (speeds[index] ?? .infinity) <= stableThreshold {
            return index
        }
        return 0
    }

    private func detectTakeaway(speeds: [CGFloat?], from start: Int, to end: Int) -> Int? {
        guard start < end else { return nil }
        let peakSpeed = speeds.compactMap { $0 }.max() ?? 0
        let threshold = peakSpeed * Self.takeawaySpeedFraction
        for index in start..<end where (speeds[index] ?? 0) >= threshold {
            return index
        }
        return nil
    }

    private func argmax(_ values: [CGFloat?], from start: Int = 0, upTo end: Int? = nil) -> Int? {
        let end = end ?? values.count
        guard start >= 0, start < end, end <= values.count else { return nil }
        var bestIndex: Int?
        var bestValue: CGFloat = -.infinity
        for index in start..<end {
            if let value = values[index], value > bestValue {
                bestValue = value
                bestIndex = index
            }
        }
        return bestIndex
    }
}
