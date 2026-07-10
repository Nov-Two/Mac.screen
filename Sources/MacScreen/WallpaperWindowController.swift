import AppKit
import AVFoundation

@MainActor
final class WallpaperWindowController: ObservableObject {
    @Published private(set) var activeURL: URL?
    @Published private(set) var isPaused = false

    private var windows: [NSWindow] = []
    private var players: [AVPlayer] = []

    @discardableResult
    func apply(videoURL: URL) -> Bool {
        stop()

        guard FileManager.default.isReadableFile(atPath: videoURL.path) else {
            return false
        }

        let screens = NSScreen.screens.isEmpty ? (NSScreen.main.map { [$0] } ?? []) : NSScreen.screens
        guard !screens.isEmpty else { return false }

        for screen in screens {
            let playerItem = AVPlayerItem(url: videoURL)
            let player = AVPlayer(playerItem: playerItem)
            player.isMuted = true
            player.actionAtItemEnd = .none

            let playerView = PlayerView(frame: screen.frame)
            playerView.player = player

            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )

            window.contentView = playerView
            window.backgroundColor = .black
            window.isOpaque = true
            window.ignoresMouseEvents = true
            window.isReleasedWhenClosed = false
            window.canHide = false
            window.hidesOnDeactivate = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
            window.orderBack(nil)

            player.play()

            windows.append(window)
            players.append(player)
        }

        activeURL = videoURL
        isPaused = false
        return true
    }

    func pause() {
        guard activeURL != nil else { return }
        players.forEach { $0.pause() }
        isPaused = true
    }

    func resume() {
        guard activeURL != nil else { return }
        players.forEach { $0.play() }
        isPaused = false
    }

    func togglePause() {
        isPaused ? resume() : pause()
    }

    func stop() {
        for player in players {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }

        for window in windows {
            window.orderOut(nil)
            window.close()
        }

        players.removeAll()
        windows.removeAll()
        activeURL = nil
        isPaused = false
    }
}
