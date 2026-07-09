import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WallpaperStore
    @ObservedObject var wallpaperController: WallpaperWindowController
    @State private var itemPendingDeletion: WallpaperItem?

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
        .alert(
            "删除素材？",
            isPresented: Binding(
                get: { itemPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        itemPendingDeletion = nil
                    }
                }
            ),
            presenting: itemPendingDeletion
        ) { item in
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if wallpaperController.activeURL == item.url {
                    wallpaperController.stop()
                }

                Task {
                    await store.delete(item)
                }
            }
        } message: { item in
            if WallpaperLibrary.isUserVideo(item.url) {
                Text("将删除这个自定义素材文件，此操作不可撤销。")
            } else {
                Text("内置素材不会从应用包中物理删除，但会从当前用户的列表中移除。")
            }
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
            Link("haowallpaper.com", destination: URL(string: "https://haowallpaper.com/")!)
            Text("下载")
                .foregroundStyle(.secondary)
            Spacer()
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

            Button(role: .destructive) {
                itemPendingDeletion = store.selectedItem
            } label: {
                Label("删除素材", systemImage: "trash")
            }
            .disabled(store.selectedItem == nil || store.isLoading)

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
