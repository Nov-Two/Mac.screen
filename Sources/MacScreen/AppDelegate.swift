import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
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

    private func showMainWindow() -> Bool {
        guard let window = NSApp.windows.first(where: { $0.identifier == .macScreenMainWindow }) else {
            return false
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }
}
