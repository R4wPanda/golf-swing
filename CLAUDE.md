# GolfSwingAnalyzer

iOS SwiftUI app (Xcode project at repo root: `GolfSwingAnalyzer.xcodeproj`,
target min iOS 17) that records or imports a golf swing video, extracts body
pose with Vision, detects swing phases, and surfaces rule-based positional
feedback. Built on a Windows machine without Xcode access, so the person
running you here is the one who actually builds/runs on-device — treat build
errors and on-device test results as ground truth over any assumption.

## Key decisions

- **Face-on camera angle only for v1** (not down-the-line). Checkpoints and
  framing guidance all assume this.
- **App shell is portrait-only**; only the capture/calibration screens allow
  landscape (`App/AppDelegate.swift` + `App/OrientationLock.swift`). A golf
  swing is a *wide* motion — landscape avoids clipping the club during
  backswing/follow-through.
- Before a real swing recording is allowed, `Capture/CalibrationView.swift`
  records a practice swing and checks for frame clipping via
  `Analysis/PoseExtraction/FrameClippingChecker.swift`.
- Deployment target is iOS 17 specifically to use
  `AVCaptureDevice.RotationCoordinator` for orientation handling.
- **Pipeline**: `VisionPoseExtractor` (AVAssetReader + Vision, runs
  `nonisolated`/off the main actor) → `HeuristicPhaseDetector` (wrist
  height/velocity extrema, averaged across both wrists — handedness-agnostic)
  → `FeedbackEngine` running the `FaceOnCheckpoints` rules. **All thresholds
  are provisional heuristics, not validated against real data** — expect to
  retune against actual swings rather than treat them as settled.
- **No results/visualization UI yet.** `ViewModels/AnalysisViewModel.swift`
  logs a structured summary to the Xcode console. A swing-path overlay and a
  real results screen are the next planned milestones (see below).
- The project uses Xcode's file-system-synchronized group
  (`PBXFileSystemSynchronizedRootGroup`) pointed at the `GolfSwingAnalyzer`
  folder — any file placed there is picked up automatically, no manual
  "Add Files to project" step needed.
- Video import (`Capture/VideoImporter.swift`, `PhotosPicker`) does **not**
  go through calibration — you can't ask someone to reposition a camera for
  footage already recorded elsewhere.

## Explicitly out of scope for v1 — flag before building toward these

Clubhead speed/sensor integration, a custom-trained ML model (Vision's
built-in body pose only), user accounts/cloud sync/swing history,
multi-camera or slow-mo-specific capture, monetization/onboarding polish.

## Current status

Done: capture + calibration (Milestones 1-2), and the full analysis pipeline
plus photo import (Milestones 3/4/6/7 combined, reordered ahead of UI at the
user's request). Not yet built: swing-path overlay on a scrubbable player
(Milestone 5), and the real results screen (Milestone 8) — both currently
stand in as console log output only.
