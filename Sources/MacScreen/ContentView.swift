import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WallpaperStore
    @ObservedObject var wallpaperController: WallpaperWindowController
    @State private var skipsDeleteConfirmation = UserDefaults.standard.bool(forKey: UserDefaultsKeys.skipsDeleteConfirmation)

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 420)
        } detail: {
            detail
        }
        .frame(minWidth: 920, minHeight: 600)
        .task {
            await store.load()
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            header

            if store.isLoading {
                ProgressView("正在读取动态壁纸...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            } else {
                List(selection: $store.selectedItems) {
                    ForEach(store.items) { item in
                        WallpaperRow(item: item)
                            .tag(item)
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MacScreen")
                        .font(.title2.weight(.semibold))
                    Text("本地动态壁纸")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        await store.importVideos()
                    }
                } label: {
                    Label("添加视频", systemImage: "plus")
                }
                .disabled(store.isLoading)
            }

            HStack(spacing: 8) {
                Button(role: .destructive) {
                    requestDeletion()
                } label: {
                    Label(deleteButtonTitle, systemImage: "trash")
                }
                .disabled(store.selectedItems.isEmpty || store.isLoading)

                Button {
                    Task {
                        await store.restoreBundledVideos()
                    }
                } label: {
                    Label("初始化资源", systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
            }
            .controlSize(.small)

            if !store.selectedItems.isEmpty {
                Text("已选择 \(store.selectedItems.count) 个素材，按住 Command 可多选。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let importMessage = store.importMessage {
                Text(importMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.bar)
    }

    private var detail: some View {
        VStack(spacing: 0) {
            wallpaperLinkBar
            preview
            controls
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var wallpaperLinkBar: some View {
        HStack(spacing: 4) {
            Text("更多精美壁纸请前往")
                .foregroundStyle(.secondary)
            Button {
                InAppBrowserWindowController.shared.show(
                    url: URL(string: "https://haowallpaper.com/")!,
                    title: "haowallpaper.com"
                ) { downloadedURL in
                    Task {
                        await store.importDownloadedResource(at: downloadedURL)
                    }
                }
            } label: {
                Text("haowallpaper.com")
                    .underline()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.link)
            Text("下载")
                .foregroundStyle(.secondary)
            Spacer()
            GitHubIconLink()
        }
        .font(.callout)
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black)

            if let item = previewItem {
                StaticWallpaperPreview(item: item)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title)
                                .font(.headline)
                                .lineLimit(1)
                            Text("\(item.resolutionText) · \(item.durationText) · \(item.sizeText)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .padding(14)
                    }
            } else {
                Text("选择一个动态壁纸开始预览")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(22)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            statusText

            Spacer()

            Button {
                wallpaperController.stop()
                UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastWallpaperPath)
            } label: {
                Label("停止", systemImage: "stop.fill")
            }
            .disabled(wallpaperController.activeURL == nil)

            Button(role: .destructive) {
                requestDeletion()
            } label: {
                Label(deleteButtonTitle, systemImage: "trash")
            }
            .disabled(store.selectedItems.isEmpty || store.isLoading)

            Button {
                guard let item = previewItem else { return }
                wallpaperController.apply(videoURL: item.url)
            } label: {
                Label("应用到桌面", systemImage: "play.rectangle.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(previewItem == nil)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(.bar)
    }

    private var statusText: some View {
        Group {
            if let activeURL = wallpaperController.activeURL {
                Text("正在使用：\(activeURL.deletingPathExtension().lastPathComponent)")
            } else if !store.selectedItems.isEmpty {
                Text("右侧为静态预览，桌面壁纸播放时不会抢占其他程序。")
            } else {
                Text("选择一个资源后可应用到桌面。")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var previewItem: WallpaperItem? {
        store.selectedItems.sorted {
            $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }.first ?? store.selectedItem
    }

    private var deleteButtonTitle: String {
        store.selectedItems.count > 1 ? "删除选中(\(store.selectedItems.count))" : "删除素材"
    }

    private func requestDeletion() {
        let items = store.selectedItems
        guard !items.isEmpty else { return }

        if !skipsDeleteConfirmation && !confirmDeletion(for: items) {
            return
        }

        if items.contains(where: { $0.url == wallpaperController.activeURL }) {
            wallpaperController.stop()
        }

        Task {
            await store.delete(items)
        }
    }

    private func deleteConfirmationMessage(for items: Set<WallpaperItem>) -> String {
        let customCount = items.filter { WallpaperLibrary.isUserVideo($0.url) }.count
        let bundledCount = items.count - customCount
        var parts: [String] = []

        if customCount > 0 {
            parts.append("将删除 \(customCount) 个自定义素材文件，此操作不可撤销")
        }

        if bundledCount > 0 {
            parts.append("将从当前用户列表中移除 \(bundledCount) 个内置素材")
        }

        return parts.joined(separator: "；") + "。"
    }

    private func confirmDeletion(for items: Set<WallpaperItem>) -> Bool {
        let alert = NSAlert()
        alert.messageText = "删除素材？"
        alert.informativeText = deleteConfirmationMessage(for: items)
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "下次不再提醒"

        let response = alert.runModal()
        if response == .alertFirstButtonReturn && alert.suppressionButton?.state == .on {
            skipsDeleteConfirmation = true
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.skipsDeleteConfirmation)
        }

        return response == .alertFirstButtonReturn
    }
}

private struct GitHubIconLink: View {
    private let profileURL = URL(string: "https://github.com/")!

    var body: some View {
        Button {
            NSWorkspace.shared.open(profileURL)
        } label: {
            if let image = Self.githubImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "link")
                    .resizable()
                    .scaledToFit()
            }
        }
        .buttonStyle(.plain)
        .frame(width: 18, height: 18)
        .contentShape(Rectangle())
        .help("GitHub 作者主页")
        .accessibilityLabel("GitHub 作者主页")
    }

    private static var githubImage: NSImage? {
        guard let url = Bundle.main.url(
            forResource: "GitHubMark",
            withExtension: "png",
            subdirectory: "Links"
        ) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}

private struct StaticWallpaperPreview: View {
    let item: WallpaperItem

    var body: some View {
        ZStack {
            Color.black

            if let image = item.thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo")
                        .font(.system(size: 38))
                    Text("暂无静态预览图")
                        .font(.callout)
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

private struct WallpaperRow: View {
    let item: WallpaperItem

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)

                Text("\(item.resolutionText) · \(item.durationText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black)

            if let image = item.thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "film")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 82, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
