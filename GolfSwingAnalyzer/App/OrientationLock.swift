import Combine

/// Shared flag read by `AppDelegate.application(_:supportedInterfaceOrientationsFor:)`.
/// The app is portrait-only everywhere except while this is `true`, which the
/// capture/calibration screens set for their own lifetime.
final class OrientationLock: ObservableObject {
    static let shared = OrientationLock()

    @Published var allowsLandscape = false

    private init() {}
}
