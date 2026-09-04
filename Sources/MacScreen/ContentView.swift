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

    private let cardWidth: CGFloat = AppTheme.cardWidth
    private let cardHeight: CGFloat = AppTheme.cardHeight
    private let columns = [GridItem(.adaptive(minimum: AppTheme.cardWidth), spacing: 16)]
    private let mainCategories = ["二次元", "风景", "人物", "其他"]

    var body: some View {
        VStack(spacing: 0) {
            header
            secondaryToolbar
            content
            footer
        }
        .frame(minWidth: 980, minHeight: 640)
        .background(AppTheme.background)
        .tint(AppTheme.accent)
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

    // MARK: - 头部（MacChromeHeader）

    private var header: some View {
        HStack(spacing: 12) {
            AppIconView()

            VStack(alignment: .leading, spacing: 1) {
                Text(AppConfiguration.appName)
                    .font(.system(size: 13, weight: .semibold))
                Text("动态壁纸")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            HeaderIconButton(
                systemImage: "arrow.clockwise",
                help: "恢复被隐藏的内置素材，不会删除自定义素材"
            ) {
                Task {
                    await store.restoreBundledVideos()
                }
            }
            .disabled(store.isLoading)

            HeaderIconButton(
                systemImage: "trash",
                help: "删除选中的素材。按住 Command 点击多个素材可批量选择后删除。",
                role: .destructive,
                action: requestDeletion
            )
            .disabled(store.selectedItems.isEmpty || store.isLoading)

            GitHubIconLink()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.hairlineBorder)
                .frame(height: 1)
        }
    }

    // MARK: - 次级工具栏（搜索 + 分段标签 + 操作）

    private var secondaryToolbar: some View {
        HStack(spacing: 16) {
            searchField

            Spacer()

            SegmentedTagControl(
                options: allCategories,
                selection: $selectedCategory,
                iconFor: categoryIcon
            )

            Spacer()

            HStack(spacing: 8) {
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

                ToolbarToggleButton(
                    systemImage: "sparkles",
                    title: "动态效果",
                    help: "控制素材卡片的 3D hover 动效。关闭后会停用连续鼠标跟踪，减轻卡顿。",
                    isOn: $enablesWallpaperCardHoverEffect
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.hairlineBorder)
                .frame(height: 1)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.secondaryText)

            TextField("搜索壁纸或标签...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .frame(width: 220)
                .help("按素材标题或自动标签搜索")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.cardSurface, in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                .stroke(AppTheme.hairlineBorder, lineWidth: 1)
        )
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
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                statusText

                Text("显示 \(filteredItems.count) / 共 \(store.items.count) 个素材")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            volumeControl

            Spacer()

            HStack(spacing: 6) {
                mediaControlButton(
                    "stop.fill",
                    help: "停止",
                    isDisabled: wallpaperController.activeURL == nil
                ) {
                    wallpaperController.stop()
                    store.clearLastWallpaper()
                }

                mediaControlButton(
                    wallpaperController.isPaused ? "play.fill" : "pause.fill",
                    help: wallpaperController.isPaused ? "继续" : "暂停",
                    isDisabled: wallpaperController.activeURL == nil
                ) {
                    wallpaperController.togglePause()
                }

                mediaControlButton(
                    "forward.fill",
                    help: "下一个",
                    isDisabled: store.items.isEmpty
                ) {
                    applyWallpaper(store.selectNextItem(after: wallpaperController.activeURL))
                }

                Button {
                    applyWallpaper(store.previewItem)
                } label: {
                    Label("应用选中", systemImage: "play.rectangle.fill")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.previewItem == nil)
                .pointingHandCursor()
            }
        }
        .controlSize(.small)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.hairlineBorder)
                .frame(height: 1)
        }
    }

    private func mediaControlButton(
        _ systemImage: String,
        help: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 26, height: 26)
                .background(
                    Color.primary.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .disabled(isDisabled)
        .help(help)
        .pointingHandCursor()
    }

    private var volumeControl: some View {
        HStack(spacing: 6) {
            Image(systemName: AppConfiguration.volumeSymbolName(for: wallpaperController.volume))
                .font(.system(size: 11))
                .frame(width: 16)
                .foregroundStyle(AppTheme.secondaryText)

            Slider(value: $wallpaperController.volume)
                .frame(width: 120)
                .controlSize(.mini)

            Text("\(Int(wallpaperController.volume * 100))%")
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(AppTheme.secondaryText)
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
        .font(.system(size: 13))
        .foregroundStyle(AppTheme.secondaryText)
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

    private var allCategories: [String] {
        ["全部", "收藏"] + mainCategories
    }

    private func categoryIcon(_ category: String) -> String? {
        switch category {
        case "全部":
            return "square.grid.2x2.fill"
        case "收藏":
            return "heart.fill"
        default:
            return nil
        }
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
