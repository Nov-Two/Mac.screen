import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: WallpaperStore
    @ObservedObject var wallpaperController: WallpaperWindowController
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
            Image(systemName: wallpaperController.volume == 0
                  ? "speaker.slash.fill"
                  : wallpaperController.volume < 0.5
                  ? "speaker.wave.1.fill"
                  : "speaker.wave.3.fill")
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

    private var deleteButtonTitle: String {
        store.selectedItems.count > 1 ? "删除选中(\(store.selectedItems.count))" : "删除素材"
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

    private var availableCategories: [String] {
        ["全部", "收藏"] + mainCategories
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
        guard let item else { return }

        store.select(item)
        if wallpaperController.apply(videoURL: item.url) {
            store.rememberLastWallpaper(item.url)
        } else {
            store.clearLastWallpaper()
        }
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

private struct WallpaperCard: View {
    let item: WallpaperItem
    let isSelected: Bool
    let isActive: Bool
    let isFavorite: Bool
    let isPaused: Bool
    let isHovering: Bool
    let isMotionEnabled: Bool
    let width: CGFloat
    let height: CGFloat
    let onSelect: () -> Void
    let onApply: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    let onTogglePause: () -> Void
    let onStop: () -> Void
    let onShowInFinder: () -> Void
    let onHover: (Bool) -> Void
    @State private var hoverMotion = WallpaperCardHoverState.idle
    @State private var isTrackingHover = false

    private let hoverConfiguration = AppConfiguration.wallpaperCardHover

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            thumbnail
                .frame(width: width, height: height)

            if isHovering || isSelected || isActive {
                overlay
                    .frame(width: width, height: height)
                    .transition(.opacity)
            }

            if isActive {
                activeBadge
                    .padding(10)
                    .frame(width: width, height: height, alignment: .topTrailing)
            } else if isFavorite {
                favoriteBadge
                    .padding(10)
                    .frame(width: width, height: height, alignment: .topTrailing)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: isSelected || isActive ? 2 : 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture(perform: onSelect)
        .pointingHandCursor()
        .rotation3DEffect(
            .degrees(isMotionEnabled ? hoverMotion.rotateX : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: hoverConfiguration.perspective
        )
        .rotation3DEffect(
            .degrees(isMotionEnabled ? hoverMotion.rotateY : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: hoverConfiguration.perspective
        )
        .scaleEffect(isMotionEnabled ? hoverMotion.scale : 1)
        .offset(
            x: isMotionEnabled ? hoverMotion.offset.width : 0,
            y: isMotionEnabled ? hoverMotion.offset.height : 0
        )
        .modifier(
            WallpaperCardHoverInteractionModifier(
                isMotionEnabled: isMotionEnabled,
                cardSize: CGSize(width: width, height: height),
                hoverConfiguration: hoverConfiguration,
                hoverMotion: $hoverMotion,
                isTrackingHover: $isTrackingHover,
                onHover: onHover
            )
        )
        .onChange(of: isMotionEnabled) { _, enabled in
            guard !enabled else { return }
            hoverMotion = .idle
        }
        .onDisappear {
            if isTrackingHover {
                isTrackingHover = false
                onHover(false)
            }
        }
        .shadow(
            color: .black.opacity(shadowOpacity),
            radius: shadowRadius,
            x: 0,
            y: hoverConfiguration.shadowYOffset + hoverMotion.strength * hoverConfiguration.shadowHoverLift
        )
        .contextMenu {
            let cfg = AppConfiguration.contextMenu

            Button {
                onApply()
            } label: {
                Label(cfg.applyLabel, systemImage: cfg.applyIcon)
            }

            if isActive {
                Button {
                    onTogglePause()
                } label: {
                    Label(isPaused ? cfg.resumeLabel : cfg.pauseLabel,
                          systemImage: isPaused ? cfg.resumeIcon : cfg.pauseIcon)
                }

                Button {
                    onStop()
                } label: {
                    Label(cfg.stopLabel, systemImage: cfg.stopIcon)
                }
            }

            Divider()

            Button {
                onShowInFinder()
            } label: {
                Label(cfg.showInFinderLabel, systemImage: cfg.showInFinderIcon)
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(cfg.deleteLabel, systemImage: cfg.deleteIcon)
            }
        }
    }

    private var thumbnail: some View {
        ZStack {
            Color.black.opacity(0.92)

            if let image = item.thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .scaleEffect(isMotionEnabled ? hoverMotion.mediaScale : AppConfiguration.wallpaperCardHover.baseMediaScale)
                    .offset(
                        x: isMotionEnabled ? hoverMotion.mediaOffset.width : 0,
                        y: isMotionEnabled ? hoverMotion.mediaOffset.height : 0
                    )
                    .clipped()
            } else {
                Image(systemName: "film")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            }

            if isMotionEnabled && hoverConfiguration.isHighlightEnabled && isHovering {
                RadialGradient(
                    colors: [
                        .white.opacity(hoverMotion.highlightOpacity),
                        .white.opacity(hoverMotion.highlightOpacity * 0.36),
                        .clear
                    ],
                    center: hoverMotion.highlightCenter,
                    startRadius: 6,
                    endRadius: max(width, height) * 0.9
                )
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
        }
    }

    private var overlay: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    .black.opacity(0.02),
                    .black.opacity(0.18),
                    .black.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.mainCategory)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.18), in: Capsule())
                        .frame(height: 22, alignment: .leading)

                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(height: 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        metadata(item.resolutionText, "rectangle")
                        metadata(item.durationText, "clock")
                    }
                    .frame(height: 18, alignment: .leading)
                }
                .frame(width: width - 112, alignment: .leading)
                .clipped()

                HStack(spacing: 7) {
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(width: 32, height: 26)
                    .help(isFavorite ? "取消收藏" : "收藏这个素材")
                    .pointingHandCursor()

                    Button(action: onApply) {
                        Image(systemName: "play.fill")
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .frame(width: 32, height: 26)
                    .help("把这个素材应用到桌面")
                    .pointingHandCursor()
                }
                .frame(width: 72, height: 26, alignment: .trailing)
                .offset(
                    x: isMotionEnabled ? hoverMotion.actionsOffset.width : 0,
                    y: isMotionEnabled ? hoverMotion.actionsOffset.height : 0
                )
            }
            .frame(width: width - 24, alignment: .bottomLeading)
            .padding(.horizontal, 12)
            .padding(.bottom, 11)
            .offset(
                x: isMotionEnabled ? hoverMotion.contentOffset.width : 0,
                y: isMotionEnabled ? hoverMotion.contentOffset.height : 0
            )
        }
    }

    private var activeBadge: some View {
        Label("使用中", systemImage: "checkmark.circle.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.black.opacity(0.45), in: Capsule())
    }

    private var favoriteBadge: some View {
        Image(systemName: "heart.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(7)
            .background(.black.opacity(0.45), in: Circle())
    }

    private var borderColor: Color {
        if isActive { return .green.opacity(0.8) }
        if isSelected { return .blue.opacity(0.75) }
        return .white.opacity(isHovering ? 0.7 : 0.24)
    }

    private var shadowOpacity: CGFloat {
        hoverConfiguration.idleShadowOpacity
            + (hoverConfiguration.hoverShadowOpacity - hoverConfiguration.idleShadowOpacity) * hoverMotion.strength
    }

    private var shadowRadius: CGFloat {
        hoverConfiguration.idleShadowRadius
            + (hoverConfiguration.hoverShadowRadius - hoverConfiguration.idleShadowRadius) * hoverMotion.strength
    }

    private func metadata(_ text: String, _ icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.88))
            .lineLimit(1)
            .truncationMode(.tail)
            .fixedSize(horizontal: true, vertical: false)
    }
}

private struct WallpaperCardHoverState: Equatable {
    let rotateX: CGFloat
    let rotateY: CGFloat
    let scale: CGFloat
    let strength: CGFloat
    let offset: CGSize
    let mediaScale: CGFloat
    let mediaOffset: CGSize
    let contentOffset: CGSize
    let actionsOffset: CGSize
    let highlightCenter: UnitPoint
    let highlightOpacity: CGFloat

    static let idle = WallpaperCardHoverState(
        rotateX: 0,
        rotateY: 0,
        scale: 1,
        strength: 0,
        offset: .zero,
        mediaScale: AppConfiguration.wallpaperCardHover.baseMediaScale,
        mediaOffset: .zero,
        contentOffset: .zero,
        actionsOffset: .zero,
        highlightCenter: .center,
        highlightOpacity: 0
    )

    init(
        rotateX: CGFloat,
        rotateY: CGFloat,
        scale: CGFloat,
        strength: CGFloat,
        offset: CGSize,
        mediaScale: CGFloat,
        mediaOffset: CGSize,
        contentOffset: CGSize,
        actionsOffset: CGSize,
        highlightCenter: UnitPoint,
        highlightOpacity: CGFloat
    ) {
        self.rotateX = rotateX
        self.rotateY = rotateY
        self.scale = scale
        self.strength = strength
        self.offset = offset
        self.mediaScale = mediaScale
        self.mediaOffset = mediaOffset
        self.contentOffset = contentOffset
        self.actionsOffset = actionsOffset
        self.highlightCenter = highlightCenter
        self.highlightOpacity = highlightOpacity
    }

    init(location: CGPoint, size: CGSize, configuration: WallpaperCardHoverConfiguration) {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        let normalizedX = Self.clamp(location.x / width, min: 0, max: 1)
        let normalizedY = Self.clamp(location.y / height, min: 0, max: 1)

        let centeredX = Self.applyDeadZone((normalizedX * 2) - 1, deadZone: configuration.deadZone)
        let centeredY = Self.applyDeadZone((normalizedY * 2) - 1, deadZone: configuration.deadZone)
        let strength = min(1, sqrt(centeredX * centeredX + centeredY * centeredY))

        let offset = CGSize(
            width: centeredX * configuration.maxOffsetX,
            height: centeredY * configuration.maxOffsetY
        )

        self.init(
            rotateX: -centeredY * configuration.maxTiltDegrees,
            rotateY: centeredX * configuration.maxTiltDegrees,
            scale: 1 + configuration.maxScaleIncrease * strength,
            strength: strength,
            offset: offset,
            mediaScale: configuration.baseMediaScale + configuration.maxMediaScaleIncrease * strength,
            mediaOffset: CGSize(
                width: offset.width * configuration.mediaOffsetMultiplier,
                height: offset.height * configuration.mediaOffsetMultiplier
            ),
            contentOffset: CGSize(
                width: offset.width * configuration.contentOffsetMultiplier,
                height: offset.height * configuration.contentOffsetMultiplier
            ),
            actionsOffset: CGSize(
                width: offset.width * configuration.actionsOffsetMultiplier,
                height: offset.height * configuration.actionsOffsetMultiplier
            ),
            highlightCenter: UnitPoint(x: normalizedX, y: normalizedY),
            highlightOpacity: configuration.highlightBaseOpacity
                + (configuration.highlightMaxOpacity - configuration.highlightBaseOpacity) * strength
        )
    }

    private static func applyDeadZone(_ value: CGFloat, deadZone: CGFloat) -> CGFloat {
        let magnitude = abs(value)
        guard magnitude > deadZone else { return 0 }
        return value.sign == .minus
            ? -((magnitude - deadZone) / (1 - deadZone))
            : (magnitude - deadZone) / (1 - deadZone)
    }

    private static func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(max, value))
    }
}

private struct WallpaperCardHoverInteractionModifier: ViewModifier {
    let isMotionEnabled: Bool
    let cardSize: CGSize
    let hoverConfiguration: WallpaperCardHoverConfiguration
    @Binding var hoverMotion: WallpaperCardHoverState
    @Binding var isTrackingHover: Bool
    let onHover: (Bool) -> Void

    func body(content: Content) -> some View {
        if isMotionEnabled {
            content.onContinuousHover(coordinateSpace: .local) { phase in
                switch phase {
                case .active(let location):
                    if !isTrackingHover {
                        isTrackingHover = true
                        onHover(true)
                    }
                    hoverMotion = WallpaperCardHoverState(
                        location: location,
                        size: cardSize,
                        configuration: hoverConfiguration
                    )
                case .ended:
                    endHover(resetMotion: true)
                }
            }
        } else {
            content.onHover { hovering in
                if hovering {
                    guard !isTrackingHover else { return }
                    isTrackingHover = true
                    onHover(true)
                } else {
                    endHover(resetMotion: false)
                }
            }
        }
    }

    private func endHover(resetMotion: Bool) {
        guard isTrackingHover else { return }
        isTrackingHover = false
        onHover(false)

        guard resetMotion else { return }
        withAnimation(.easeOut(duration: hoverConfiguration.resetAnimationDuration)) {
            hoverMotion = .idle
        }
    }
}

private struct AppIconView: View {
    var body: some View {
        ZStack {
            if let image = NSImage(named: "MacScreenIcon") {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help("MacScreen")
    }
}

private struct ToolbarIconButton: View {
    let systemImage: String
    let title: String
    let help: String
    var isActive = false
    var role: ButtonRole?
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .medium))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(background, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .help(help)
        .pointingHandCursor()
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }

    private var background: Color {
        if role == .destructive && isHovering {
            return .red.opacity(0.13)
        }

        if isActive {
            return Color.accentColor.opacity(0.18)
        }

        return Color(nsColor: .controlBackgroundColor).opacity(isHovering ? 1 : 0.78)
    }

    private var foreground: Color {
        if role == .destructive && isHovering {
            return .red
        }

        return isActive ? .accentColor : .primary
    }
}

private struct ToolbarToggleButton: View {
    let systemImage: String
    let title: String
    let help: String
    @Binding var isOn: Bool
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .medium))
                .labelStyle(.titleAndIcon)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(background, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .help(help)
        .pointingHandCursor()
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }

    private var background: Color {
        Color(nsColor: .controlBackgroundColor).opacity(isHovering ? 1 : 0.78)
    }
}

private struct GitHubIconLink: View {
    private let profileURL = AppConfiguration.githubProfileURL

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
        .pointingHandCursor()
    }

    private static var githubImage: NSImage? {
        guard let url = Bundle.main.url(
            forResource: "GitHubMark",
            withExtension: "png",
            subdirectory: AppConfiguration.linkDirectoryName
        ) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}

private enum AppTheme {
    static let background = Color(nsColor: .windowBackgroundColor)
}

struct PointingHandCursorModifier: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                guard isEnabled else {
                    popIfNeeded()
                    return
                }

                if hovering {
                    guard !isHovering else { return }
                    NSCursor.pointingHand.push()
                    isHovering = true
                } else {
                    popIfNeeded()
                }
            }
            .onChange(of: isEnabled) { _, enabled in
                if !enabled {
                    popIfNeeded()
                }
            }
            .onDisappear {
                popIfNeeded()
            }
    }

    private func popIfNeeded() {
        guard isHovering else { return }
        NSCursor.pop()
        isHovering = false
    }
}

extension View {
    func pointingHandCursor() -> some View {
        modifier(PointingHandCursorModifier())
    }
}

private extension WallpaperItem {
    var displayTags: [String] {
        let separators = CharacterSet(charactersIn: " -_[]【】()（）·")
            .union(.whitespacesAndNewlines)
        let rawTags = title
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let filtered = rawTags.filter { tag in
            tag != "哲风壁纸" && tag != "动态壁纸"
        }

        return Array(filtered.prefix(6))
    }

    var mainCategory: String {
        let text = (title + " " + displayTags.joined(separator: " ")).lowercased()

        if text.contains("二次元")
            || text.contains("动漫")
            || text.contains("动画")
            || text.contains("线稿")
            || text.contains("kuroha")
        {
            return "二次元"
        }

        if text.contains("风景")
            || text.contains("云")
            || text.contains("山")
            || text.contains("海")
            || text.contains("户外")
            || text.contains("露营")
        {
            return "风景"
        }

        if text.contains("少女")
            || text.contains("甜妹")
            || text.contains("人物")
            || text.contains("原神")
        {
            return "人物"
        }

        return "其他"
    }
}
