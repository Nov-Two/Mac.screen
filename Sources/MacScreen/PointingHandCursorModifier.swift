import AppKit
import SwiftUI

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
