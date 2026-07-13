import SwiftUI

struct PreferencesView: View {
    @ObservedObject var store: WallpaperStore
    var checkLowBatteryNow: () -> Void

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

            playbackSettings
                .tabItem {
                    Label("播放", systemImage: "play.rectangle")
                }

            downloadSettings
                .tabItem {
                    Label("下载", systemImage: "arrow.down.circle")
                }
        }
        .frame(width: 520, height: 320)
        .padding(20)
    }

    private var generalSettings: some View {
        Form {
            Toggle(
                "开机启动",
                isOn: binding(
                    get: { store.opensAtLogin },
                    toggle: store.toggleOpensAtLogin
                )
            )

            Toggle(
                "启动时恢复上次壁纸",
                isOn: binding(
                    get: { store.restoresLastWallpaperOnLaunch },
                    toggle: store.toggleRestoresLastWallpaperOnLaunch
                )
            )

            Button {
                store.openUserVideoDirectory()
            } label: {
                Label("打开用户素材目录", systemImage: "folder")
            }
            .pointingHandCursor()

            Button {
                store.openBundledVideoDirectory()
            } label: {
                Label("打开内置素材目录", systemImage: "shippingbox")
            }
            .pointingHandCursor()

            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
    }

    private var playbackSettings: some View {
        Form {
            Toggle(
                "低电量时暂停并提醒",
                isOn: binding(
                    get: { store.pausesOnLowBattery },
                    toggle: {
                        store.togglePausesOnLowBattery()
                        checkLowBatteryNow()
                    }
                )
            )

            LabeledContent("触发阈值") {
                Text("\(AppConfiguration.lowBatteryPauseThresholdPercent)%")
                    .foregroundStyle(.secondary)
            }

            LabeledContent("检测间隔") {
                Text("\(Int(AppConfiguration.lowBatteryMonitorInterval)) 秒")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var downloadSettings: some View {
        Form {
            Toggle(
                "导入成功后清理下载源文件",
                isOn: binding(
                    get: { store.cleansDownloadedResourcesAfterImport },
                    toggle: store.toggleCleansDownloadedResourcesAfterImport
                )
            )

            LabeledContent("下载行为") {
                Text("不限制来源，下载完成后自动尝试导入")
                .foregroundStyle(.secondary)
            }

            Button {
                store.openDownloadsDirectory()
            } label: {
                Label("打开下载目录", systemImage: "folder")
            }
            .pointingHandCursor()
        }
        .formStyle(.grouped)
    }

    private func binding(get: @escaping () -> Bool, toggle: @escaping () -> Void) -> Binding<Bool> {
        Binding(
            get: get,
            set: { newValue in
                if newValue != get() {
                    toggle()
                }
            }
        )
    }
}
