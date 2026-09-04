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
        Color(nsColor: .controlBackgroundColor).opacity(isHovering ? 1 : 0.78)
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

enum AppTheme {
    static let background = Color(nsColor: .windowBackgroundColor)
}
