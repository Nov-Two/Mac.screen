import AppKit
import IOKit.ps

@MainActor
final class LowBatteryMonitorController {
    private weak var store: WallpaperStore?
    private weak var wallpaperController: WallpaperWindowController?
    private var timer: Timer?
    private var isShowingAlert = false
    private var hasAlertedForCurrentLowBatteryState = false

    func configure(store: WallpaperStore, wallpaperController: WallpaperWindowController) {
        self.store = store
        self.wallpaperController = wallpaperController

        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: AppConfiguration.lowBatteryMonitorInterval, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.checkPowerState()
                }
            }
        }

        checkPowerState()
    }

    func checkPowerState() {
        guard
            let store,
            let wallpaperController,
            store.pausesOnLowBattery
        else {
            hasAlertedForCurrentLowBatteryState = false
            return
        }

        guard let batteryState = BatteryPowerState.current else {
            hasAlertedForCurrentLowBatteryState = false
            return
        }

        guard batteryState.isLowBattery else {
            hasAlertedForCurrentLowBatteryState = false
            return
        }

        guard
            wallpaperController.activeURL != nil,
            !isShowingAlert,
            !hasAlertedForCurrentLowBatteryState
        else {
            return
        }

        hasAlertedForCurrentLowBatteryState = true
        wallpaperController.pause()
        showLowBatteryDecisionAlert(percent: batteryState.percent)
    }

    private func showLowBatteryDecisionAlert(percent: Int) {
        isShowingAlert = true
        defer {
            isShowingAlert = false
        }

        let alert = NSAlert()
        alert.messageText = "电量较低，已暂停动态壁纸"
        alert.informativeText = "当前电量约 \(percent)%。动态壁纸已暂停，以减少耗电。你可以停止当前壁纸，或退出 \(AppConfiguration.appName)。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "停止壁纸")
        alert.addButton(withTitle: "退出应用")
        alert.addButton(withTitle: "继续播放")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            wallpaperController?.stop()
            store?.clearLastWallpaper()
        case .alertSecondButtonReturn:
            NSApp.terminate(nil)
        default:
            wallpaperController?.resume()
        }
    }
}

private struct BatteryPowerState {
    let percent: Int
    let isOnBatteryPower: Bool

    var isLowBattery: Bool {
        isOnBatteryPower && percent <= AppConfiguration.lowBatteryPauseThresholdPercent
    }

    static var current: BatteryPowerState? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return nil
        }

        guard let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }

        for source in sources {
            guard
                let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                let currentCapacity = description[kIOPSCurrentCapacityKey as String] as? Int,
                let powerSourceState = description[kIOPSPowerSourceStateKey as String] as? String
            else {
                continue
            }

            return BatteryPowerState(
                percent: currentCapacity,
                isOnBatteryPower: powerSourceState == (kIOPSBatteryPowerValue as String)
            )
        }

        return nil
    }
}
