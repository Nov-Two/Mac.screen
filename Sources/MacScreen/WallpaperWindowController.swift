import AppKit
import AVFoundation

@MainActor
final class WallpaperWindowController: ObservableObject {
    @Published private(set) var activeURL: URL?
    @Published private(set) var isPaused = false
    @Published var volume: Float = {
        let saved = UserDefaults.standard.float(forKey: UserDefaultsKeys.wallpaperVolume)
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.wallpaperVolume) != nil ? saved : 0
    }() {
        didSet {
            let clamped = max(0, min(1, volume))
            if volume != clamped { volume = clamped }
            players.forEach { $0.volume = volume }
            volumeOverlays.forEach { $0.volume = volume }
            UserDefaults.standard.set(volume, forKey: UserDefaultsKeys.wallpaperVolume)
        }
    }

    private var windows: [NSWindow] = []
    private var overlayWindows: [NSWindow] = []
    private var players: [AVPlayer] = []
    private var volumeOverlays: [VolumeOverlayView] = []

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
            player.isMuted = false
            player.volume = volume
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

            // Volume overlay at bottom-center of the screen
            let overlayWidth: CGFloat = 180
            let overlayHeight: CGFloat = 28
            let overlayFrame = NSRect(
                x: (screen.frame.width - overlayWidth) / 2,
                y: 24,
                width: overlayWidth,
                height: overlayHeight
            )
            let overlayView = VolumeOverlayView(frame: overlayFrame)
            overlayView.volume = volume
            overlayView.onVolumeChanged = { [weak self] newVolume in
                self?.volume = newVolume
            }

            // Use a child window so it floats above the wallpaper but stays on the same level
            let overlayWindow = NSWindow(
                contentRect: overlayFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )
            overlayWindow.contentView = overlayView
            overlayWindow.backgroundColor = .clear
            overlayWindow.isOpaque = false
            overlayWindow.ignoresMouseEvents = false
            overlayWindow.isReleasedWhenClosed = false
            overlayWindow.canHide = false
            overlayWindow.hidesOnDeactivate = false
            overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            overlayWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
            overlayWindow.orderFront(nil)

            windows.append(window)
            players.append(player)
            volumeOverlays.append(overlayView)
            overlayWindows.append(overlayWindow)
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

        for window in overlayWindows {
            window.orderOut(nil)
            window.close()
        }

        players.removeAll()
        windows.removeAll()
        volumeOverlays.removeAll()
        overlayWindows.removeAll()
        activeURL = nil
        isPaused = false
    }
}
