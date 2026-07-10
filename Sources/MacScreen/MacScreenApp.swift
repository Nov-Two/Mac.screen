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
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updateController: softwareUpdateController)
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
}
