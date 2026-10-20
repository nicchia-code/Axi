import AppKit
import Foundation
import AxiScreen

/// The app in front when a global shortcut was pressed, kept for reading the screen.
@MainActor
final class AppInPrimoPiano {
    static let shared = AppInPrimoPiano()

    /// The app in front at the last shortcut; `nil` when there was none, or Axi was in front.
    private(set) var ultima: ApplicationSnapshot?

    /// The last app other than Axi that came to the front. An archiving request made while Axi is in front reads it.
    private(set) var ultimaAltra: ApplicationSnapshot?

    private init() {
        let front = FrontmostApplication.current()
        ultimaAltra = front?.processIdentifier == ProcessInfo.processInfo.processIdentifier ? nil : front
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  application.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
                return
            }
            let snapshot = ApplicationSnapshot(
                bundleIdentifier: application.bundleIdentifier,
                name: application.localizedName ?? "",
                processIdentifier: application.processIdentifier)
            Task { @MainActor in self?.ultimaAltra = snapshot }
        }
    }

    /// Stores the app in front now. Axi is never stored: when it is in front, there is no app to read.
    func registraAppInPrimoPiano() {
        let inPrimoPiano = FrontmostApplication.current()
        let processoDiAxi = ProcessInfo.processInfo.processIdentifier
        ultima = inPrimoPiano?.processIdentifier == processoDiAxi ? nil : inPrimoPiano
    }

    /// The app an archiving request reads: the app in front when it was made or, when Axi was in front,
    /// the last other app that came to the front, if it is still running. Nil when there is none.
    var bersaglioArchiviazione: ApplicationSnapshot? {
        if let ultima { return ultima }
        guard let altra = ultimaAltra,
              let app = NSRunningApplication(processIdentifier: altra.processIdentifier),
              !app.isTerminated else {
            return nil
        }
        return altra
    }
}
