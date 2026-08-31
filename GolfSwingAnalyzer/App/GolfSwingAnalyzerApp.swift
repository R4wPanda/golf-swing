import SwiftUI

@main
struct GolfSwingAnalyzerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            StartView()
        }
    }
}
