import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WallpaperStore
    @ObservedObject var wallpaperController: WallpaperWindowController

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
                List(selection: $store.selectedItem) {
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
        VStack(alignment: .leading, spacing: 6) {
            Text("MacScreen")
                .font(.title2.weight(.semibold))
            Text("本地动态壁纸")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.bar)
    }

    private var detail: some View {
        VStack(spacing: 0) {
            preview
            controls
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black)

            if let item = store.selectedItem {
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

            Button {
                guard let item = store.selectedItem else { return }
                wallpaperController.apply(videoURL: item.url)
            } label: {
                Label("应用到桌面", systemImage: "play.rectangle.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.selectedItem == nil)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(.bar)
    }

    private var statusText: some View {
        Group {
            if let activeURL = wallpaperController.activeURL {
                Text("正在使用：\(activeURL.deletingPathExtension().lastPathComponent)")
            } else if store.selectedItem != nil {
                Text("右侧为静态预览，桌面壁纸播放时不会抢占其他程序。")
            } else {
                Text("选择一个资源后可应用到桌面。")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .lineLimit(1)
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
