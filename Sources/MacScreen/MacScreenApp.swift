import AppKit
import SwiftUI

@main
struct MacScreenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = WallpaperStore()
    @StateObject private var wallpaperController = WallpaperWindowController()
    private let statusBarController = StatusBarController()
    private let lowBatteryMonitorController = LowBatteryMonitorController()
    private let softwareUpdateController = SoftwareUpdateController()

    var body: some Scene {
        WindowGroup("MacScreen") {
            ContentView(
                store: store,
                wallpaperController: wallpaperController
            )
            .frame(minWidth: 980, minHeight: 640)
            .background(MainWindowAccessor())
            .onAppear {
                configureStatusBarController()
                lowBatteryMonitorController.configure(store: store, wallpaperController: wallpaperController)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                wallpaperController.stop()
            }
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About \(AppConfiguration.appName)") {
                    showAboutPanel()
                }
            }

            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updateController: softwareUpdateController)
            }

            CommandGroup(replacing: .help) {
                Button(AppConfiguration.helpPanel.menuTitle) {
                    showHelpPanel()
                }
            }
        }

        Settings {
            PreferencesView(
                store: store,
                checkLowBatteryNow: lowBatteryMonitorController.checkPowerState
            )
        }
    }

    private func configureStatusBarController() {
        statusBarController.configure(store: store, wallpaperController: wallpaperController)
        statusBarController.showMainWindow = {
            appDelegate.showMainWindow()
        }
        statusBarController.importVideos = {
            Task {
                await store.importVideos()
            }
        }
        statusBarController.restoreBundledVideos = {
            Task {
                await store.restoreBundledVideos()
            }
        }
        statusBarController.applySelectedWallpaper = {
            applyWallpaper(store.previewItem)
        }
        statusBarController.applyNextWallpaper = {
            applyWallpaper(store.selectNextItem(after: wallpaperController.activeURL))
        }
        statusBarController.stopWallpaper = {
            wallpaperController.stop()
            store.clearLastWallpaper()
        }
        statusBarController.togglePause = {
            wallpaperController.togglePause()
        }
        statusBarController.toggleRestoreOnLaunch = {
            store.toggleRestoresLastWallpaperOnLaunch()
        }
        statusBarController.toggleOpenAtLogin = {
            store.toggleOpensAtLogin()
        }
        statusBarController.togglePauseOnLowBattery = {
            store.togglePausesOnLowBattery()
            lowBatteryMonitorController.checkPowerState()
        }
        statusBarController.openWallpaperWebsite = {
            InAppBrowserWindowController.shared.show(
                url: AppConfiguration.wallpaperWebsiteURL,
                title: AppConfiguration.wallpaperWebsiteTitle
            ) { downloadedURL in
                Task {
                    await store.importDownloadedResource(at: downloadedURL)
                }
            }
        }
        statusBarController.openPreferences = {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func applyWallpaper(_ item: WallpaperItem?) {
        guard let item else { return }

        if wallpaperController.apply(videoURL: item.url) {
            store.rememberLastWallpaper(item.url)
        } else {
            store.clearLastWallpaper()
        }
    }

    private func showAboutPanel() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let credits = NSAttributedString(
            string: AppConfiguration.aboutPanel.credits,
            attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: paragraphStyle
            ]
        )

        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(
            options: [
                .credits: credits
            ]
        )
    }

    private func showHelpPanel() {
        let configuration = AppConfiguration.helpPanel
        let alert = NSAlert()
        alert.messageText = configuration.title
        alert.informativeText = configuration.informativeText.isEmpty
            ? configuration.message
            : "\(configuration.message)\n\n\(configuration.informativeText)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: configuration.primaryButtonTitle)
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
