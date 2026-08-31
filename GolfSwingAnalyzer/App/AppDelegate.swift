import UIKit

/// SwiftUI has no per-screen orientation lock, so this UIKit hook is the
/// standard way to make most of the app portrait-only while letting the
/// capture/calibration screens rotate freely (`OrientationLock.shared`).
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationLock.shared.allowsLandscape ? [.portrait, .landscapeLeft, .landscapeRight] : .portrait
    }
}
