import SwiftUI

/// Entry point of Axi. An accessory app: no Dock icon, no window at launch.
/// The dot, the shortcuts and the services are started from `AppDelegate`.
@main
struct AxiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
