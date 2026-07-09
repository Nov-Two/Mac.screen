import AppKit
import AVFoundation

final class PlayerView: NSView {
    private let playerLayer = AVPlayerLayer()
    private var endObserver: NSObjectProtocol?

    var player: AVPlayer? {
        get { playerLayer.player }
        set {
            removeEndObserver()
            playerLayer.player = newValue
            observeLoopingIfNeeded()
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        playerLayer.videoGravity = .resizeAspectFill
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        playerLayer.videoGravity = .resizeAspectFill
        layer?.addSublayer(playerLayer)
    }

    deinit {
        removeEndObserver()
        playerLayer.player?.pause()
        playerLayer.player = nil
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }

    private func observeLoopingIfNeeded() {
        guard let item = player?.currentItem else { return }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
    }

    private func removeEndObserver() {
        guard let endObserver else { return }
        NotificationCenter.default.removeObserver(endObserver)
        self.endObserver = nil
    }
}
