import AppKit
import AVFoundation

@MainActor
final class WallpaperWindowController: ObservableObject {
    @Published private(set) var activeURL: URL?

    private var windows: [NSWindow] = []
    private var players: [AVPlayer] = []

    func apply(videoURL: URL) {
        stop()

        guard FileManager.default.isReadableFile(atPath: videoURL.path) else {
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastWallpaperPath)
            return
        }

        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

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

        activeURL = videoURL
        UserDefaults.standard.set(videoURL.path, forKey: UserDefaultsKeys.lastWallpaperPath)
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
    }
}
