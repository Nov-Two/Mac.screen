import AppKit
import SwiftUI

struct AppIconView: View {
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

struct ToolbarIconButton: View {
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
            return AppTheme.destructive.opacity(0.13)
        }

        if isActive {
            return AppTheme.accent.opacity(0.18)
        }

        return Color.primary.opacity(isHovering ? 0.08 : 0)
    }

    private var foreground: Color {
        if role == .destructive && isHovering {
            return AppTheme.destructive
        }

        return isActive ? AppTheme.accent : .primary
    }
}

struct ToolbarToggleButton: View {
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
        Color.primary.opacity(isHovering ? 0.08 : 0)
    }
}

struct GitHubIconLink: View {
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

/// 图标按钮，用于头部工具区（刷新/删除/GitHub），仅显示图标。
struct HeaderIconButton: View {
    let systemImage: String
    let help: String
    var role: ButtonRole?
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 28, height: 28)
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
            return AppTheme.destructive.opacity(0.13)
        }

        return Color.primary.opacity(isHovering ? 0.08 : 0)
    }

    private var foreground: Color {
        if role == .destructive && isHovering {
            return AppTheme.destructive
        }

        return .primary
    }
}

/// 分段式标签控件，对应 Figma 的 Segmented Tag Control。
struct SegmentedTagControl: View {
    let options: [String]
    @Binding var selection: String
    let iconFor: (String) -> String?

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                segmentButton(option)
            }
        }
        .padding(2)
        .background(AppTheme.cardSurface, in: RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
                .stroke(AppTheme.hairlineBorder, lineWidth: 1)
        )
    }

    private func segmentButton(_ option: String) -> some View {
        let isSelected = selection == option

        return Button {
            selection = option
        } label: {
            HStack(spacing: 5) {
                if let icon = iconFor(option) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }

                Text(option)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.primary : AppTheme.secondaryText)
            .padding(.horizontal, 11)
            .padding(.vertical, 4)
            .background(
                isSelected ? AppTheme.accent.opacity(0.18) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
    }
}

enum AppTheme {
    // MARK: - 颜色（随系统深浅色自适应）
    /// 主背景：深色 #1D1D1F / 浅色系统窗口背景
    static let background = Color(nsColor: .windowBackgroundColor)
    /// 次级文字：深色 #86868B / 浅色系统次级标签色
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    /// 强调蓝 #0071E3
    static let accent = Color(red: 0.0, green: 0.443, blue: 0.890)
    /// 危险红 #EF4444
    static let destructive = Color(red: 0.937, green: 0.267, blue: 0.267)
    /// 卡片表面，略亮于背景，用于元信息页脚与按钮
    static let cardSurface = Color(nsColor: .controlBackgroundColor)
    /// 细分割线（hairline border），随系统自适应
    static let hairlineBorder = Color(nsColor: .separatorColor)

    // MARK: - 卡片尺寸（按 Figma 349×240 等比缩放）
    static let cardWidth: CGFloat = 300
    static let cardHeight: CGFloat = 206
    static let cardCornerRadius: CGFloat = 14
    /// 艺术图块高度，页脚高度 = cardHeight - artworkHeight
    static let cardArtworkHeight: CGFloat = 151

    // MARK: - 通用圆角
    static let controlCornerRadius: CGFloat = 8
}
