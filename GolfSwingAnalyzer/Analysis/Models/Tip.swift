enum TipSeverity {
    case info
    case suggestion
}

struct Tip {
    let checkpointID: String
    let phase: SwingPhase
    let message: String
    let severity: TipSeverity
}
