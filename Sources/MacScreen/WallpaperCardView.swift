import AppKit
import SwiftUI

struct WallpaperCard: View {
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

struct WallpaperCardHoverState: Equatable {
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

struct WallpaperCardHoverInteractionModifier: ViewModifier {
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
