import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WallpaperStore
    @ObservedObject var wallpaperController: WallpaperWindowController
    let statusBarController: StatusBarController
    @Environment(\.openSettings) private var openSettings
    @State private var skipsDeleteConfirmation = UserDefaults.standard.bool(forKey: UserDefaultsKeys.skipsDeleteConfirmation)
    @State private var enablesWallpaperCardHoverEffect = UserDefaults.standard.object(forKey: UserDefaultsKeys.enablesWallpaperCardHoverEffect) as? Bool ?? true
    @State private var searchText = ""
    @State private var selectedCategory = "全部"
    @State private var hoveredItemID: URL?

    private let cardWidth: CGFloat = 286
    private let cardHeight: CGFloat = 161
    private let columns = Array(repeating: GridItem(.fixed(286), spacing: 18), count: 3)
    private let mainCategories = ["二次元", "风景", "人物", "其他"]

    var body: some View {
        VStack(spacing: 0) {
            topArea
            content
            footer
        }
        .frame(minWidth: 980, minHeight: 600)
        .background(AppTheme.background)
        .onChange(of: enablesWallpaperCardHoverEffect) { _, enabled in
            UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.enablesWallpaperCardHoverEffect)
        }
        .task {
            await store.load()
            restoreLastWallpaperIfNeeded()
        }
        .onAppear {
            statusBarController.openPreferences = { [openSettings] in
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            AppIconView()

            TextField("搜索标题或标签", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))
                .frame(width: 250)
                .help("按素材标题或自动标签搜索")

            Spacer()

            ToolbarIconButton(
                systemImage: "sparkles",
                title: "发现更多",
                help: "打开 haowallpaper.com 下载更多壁纸",
                action: openWallpaperWebsite
            )

            ToolbarIconButton(
                systemImage: "plus",
                title: "添加",
                help: "导入本地 mp4、mov 或 m4v 视频"
            ) {
                Task {
                    await store.importVideos()
                }
            }
            .disabled(store.isLoading)

            ToolbarIconButton(
                systemImage: "arrow.clockwise",
                title: "初始化",
                help: "恢复被隐藏的内置素材，不会删除自定义素材"
            ) {
                Task {
                    await store.restoreBundledVideos()
                }
            }
            .disabled(store.isLoading)

            ToolbarToggleButton(
                systemImage: "sparkles",
                title: "动态效果",
                help: "控制素材卡片的 3D hover 动效。关闭后会停用连续鼠标跟踪，减轻卡顿。",
                isOn: $enablesWallpaperCardHoverEffect
            )

            ToolbarIconButton(
                systemImage: "trash",
                title: "删除",
                help: "删除选中的素材。按住 Command 点击多个素材可批量选择后删除。",
                role: .destructive,
                action: requestDeletion
            )
            .disabled(store.selectedItems.isEmpty || store.isLoading)

            GitHubIconLink()
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.bar)
    }

    private var categoryBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                categoryButton("全部")
                categoryButton("收藏")
            }
            .fixedSize()

            Divider()
                .frame(height: 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(scrollableCategories, id: \.self) { category in
                        categoryButton(category)
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 10)
        .background(.bar)
    }

    private var topArea: some View {
        VStack(spacing: 0) {
            toolbar
            categoryBar
        }
    }

    private var content: some View {
        Group {
            if store.isLoading {
                ProgressView("正在读取动态壁纸...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = store.errorMessage {
                ContentUnavailableView(
                    "没有可用素材",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text(errorMessage)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredItems.isEmpty {
                ContentUnavailableView(
                    emptyStateTitle,
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text(emptyStateDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(filteredItems) { item in
                            WallpaperCard(
                                item: item,
                                isSelected: store.selectedItems.contains(item),
                                isActive: wallpaperController.activeURL == item.url,
                                isFavorite: store.isFavorite(item),
                                isPaused: wallpaperController.isPaused,
                                isHovering: hoveredItemID == item.id,
                                isMotionEnabled: enablesWallpaperCardHoverEffect,
                                width: cardWidth,
                                height: cardHeight,
                                onSelect: {
                                    select(item)
                                },
                                onApply: {
                                    applyWallpaper(item)
                                },
                                onFavorite: {
                                    store.toggleFavorite(item)
                                },
                                onDelete: {
                                    store.selectedItems = [item]
                                    requestDeletion()
                                },
                                onTogglePause: {
                                    wallpaperController.togglePause()
                                },
                                onStop: {
                                    wallpaperController.stop()
                                    store.clearLastWallpaper()
                                },
                                onShowInFinder: {
                                    store.openItemInFinder(item)
                                },
                                onHover: { isHovering in
                                    hoveredItemID = isHovering ? item.id : (hoveredItemID == item.id ? nil : hoveredItemID)
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            statusText

            Text("显示 \(filteredItems.count) / 共 \(store.items.count) 个素材")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)

            volumeControl

            Spacer()

            Button {
                wallpaperController.stop()
                store.clearLastWallpaper()
            } label: {
                Label("停止", systemImage: "stop.fill")
            }
            .disabled(wallpaperController.activeURL == nil)
            .pointingHandCursor()

            Button {
                wallpaperController.togglePause()
            } label: {
                Label(
                    wallpaperController.isPaused ? "继续" : "暂停",
                    systemImage: wallpaperController.isPaused ? "play.fill" : "pause.fill"
                )
            }
            .disabled(wallpaperController.activeURL == nil)
            .pointingHandCursor()

            Button {
                applyWallpaper(store.selectNextItem(after: wallpaperController.activeURL))
            } label: {
                Label("下一个", systemImage: "forward.fill")
            }
            .disabled(store.items.isEmpty)
            .pointingHandCursor()

            Button {
                applyWallpaper(store.previewItem)
            } label: {
                Label("应用选中", systemImage: "play.rectangle.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.previewItem == nil)
            .pointingHandCursor()
        }
        .controlSize(.small)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var volumeControl: some View {
        HStack(spacing: 6) {
            Image(systemName: AppConfiguration.volumeSymbolName(for: wallpaperController.volume))
                .font(.system(size: 11))
                .frame(width: 16)
                .foregroundStyle(.secondary)

            Slider(value: $wallpaperController.volume)
                .frame(width: 100)
                .controlSize(.mini)

            Text("\(Int(wallpaperController.volume * 100))%")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private var statusText: some View {
        Group {
            if let activeURL = wallpaperController.activeURL {
                Text("\(wallpaperController.isPaused ? "已暂停" : "正在使用")：\(activeURL.deletingPathExtension().lastPathComponent)")
            } else if let item = store.previewItem {
                Text("已选择：\(item.title)")
            } else {
                Text("选择素材后可应用到桌面。")
            }
        }
        .font(.system(size: 14))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }

    private var filteredItems: [WallpaperItem] {
        store.items.filter { item in
            let categoryRequiresFavorite = selectedCategory == "收藏"
            let matchesFavorites = !categoryRequiresFavorite || store.isFavorite(item)
            let matchesCategory = selectedCategory == "全部"
                || selectedCategory == "收藏"
                || item.mainCategory == selectedCategory
            let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = normalizedQuery.isEmpty
                || item.title.localizedCaseInsensitiveContains(normalizedQuery)
                || item.displayTags.contains { $0.localizedCaseInsensitiveContains(normalizedQuery) }

            return matchesFavorites && matchesCategory && matchesSearch
        }
    }

    private var scrollableCategories: [String] {
        mainCategories
    }

    private var emptyStateTitle: String {
        if selectedCategory == "收藏" {
            return "还没有收藏素材"
        }

        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "没有匹配的素材"
        }

        return "这个分类暂无素材"
    }

    private var emptyStateDescription: String {
        if selectedCategory == "收藏" {
            return "把鼠标移到素材上，点击爱心即可收藏。"
        }

        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "换一个关键词，或清空搜索后再试。"
        }

        return "请选择其他分类，或导入更多动态壁纸。"
    }

    private func categoryButton(_ category: String) -> some View {
        Button {
            selectedCategory = category
        } label: {
            categoryLabel(category)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(height: 30)
                .background(
                    selectedCategory == category ? Color.accentColor.opacity(0.16) : Color.clear,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(selectedCategory == category ? .primary : .secondary)
        .help(categoryHelp(category))
        .pointingHandCursor()
    }

    private func categoryHelp(_ category: String) -> String {
        switch category {
        case "全部":
            return "显示所有素材"
        case "收藏":
            return "只显示已收藏素材"
        default:
            return "筛选 \(category) 分类素材"
        }
    }

    private func categoryLabel(_ category: String) -> some View {
        HStack(spacing: 5) {
            if category == "全部" {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 11, weight: .semibold))
            } else if category == "收藏" {
                Image(systemName: "heart.fill")
                    .font(.system(size: 11, weight: .semibold))
            }

            Text(category)
        }
    }

    private func select(_ item: WallpaperItem) {
        if NSEvent.modifierFlags.contains(.command) {
            if store.selectedItems.contains(item) {
                var selectedItems = store.selectedItems
                selectedItems.remove(item)
                store.selectedItems = selectedItems
                store.selectedItem = selectedItems.sorted {
                    $0.title.localizedStandardCompare($1.title) == .orderedAscending
                }.first
            } else {
                store.selectedItems.insert(item)
                store.selectedItem = item
            }
        } else {
            store.select(item)
        }
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

    private func restoreLastWallpaperIfNeeded() {
        guard
            store.restoresLastWallpaperOnLaunch,
            wallpaperController.activeURL == nil,
            let item = store.previewItem
        else {
            return
        }

        applyWallpaper(item)
    }

    private func applyWallpaper(_ item: WallpaperItem?) {
        store.applyWallpaper(item, with: wallpaperController)
    }

    private func openWallpaperWebsite() {
        InAppBrowserWindowController.shared.show(
            url: AppConfiguration.wallpaperWebsiteURL,
            title: AppConfiguration.wallpaperWebsiteTitle
        ) { downloadedURL in
            Task {
                await store.importDownloadedResource(at: downloadedURL)
            }
        }
    }

    private func deleteConfirmationMessage(for items: Set<WallpaperItem>) -> String {
        let customCount = items.filter { store.isUserVideo($0.url) }.count
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
