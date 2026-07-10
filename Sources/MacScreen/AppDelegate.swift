import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard enforceSingleInstance() else { return }
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if showMainWindow() {
            return false
        }

        sender.sendAction(#selector(NSWindow.newWindowForTab(_:)), to: nil, from: nil)
        DispatchQueue.main.async {
            _ = self.showMainWindow()
        }
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @discardableResult
    func showMainWindow() -> Bool {
        guard let window = NSApp.windows.first(where: { $0.identifier == .macScreenMainWindow }) else {
            return false
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }

    private func enforceSingleInstance() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return true
        }

        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let existingApplication = NSWorkspace.shared.runningApplications.first { application in
            application.bundleIdentifier == bundleIdentifier
                && application.processIdentifier != currentProcessIdentifier
        }

        guard let existingApplication else {
            return true
        }

        if #available(macOS 14.0, *) {
            existingApplication.activate()
        } else {
            existingApplication.activate(options: [.activateAllWindows])
        }
        NSApp.terminate(nil)
        return false
    }
}
