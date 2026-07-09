import SwiftUI

@main
struct MacScreenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = WallpaperStore()
    @StateObject private var wallpaperController = WallpaperWindowController()
    private let softwareUpdateController = SoftwareUpdateController()

    var body: some Scene {
        WindowGroup("MacScreen") {
            ContentView(
                store: store,
                wallpaperController: wallpaperController
            )
            .frame(minWidth: 980, minHeight: 640)
            .background(MainWindowAccessor())
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                wallpaperController.stop()
            }
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updateController: softwareUpdateController)
            }
        }
    }
}
