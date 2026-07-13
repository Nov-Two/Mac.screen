import AppKit

final class VolumeOverlayView: NSView {
    private let iconView: NSImageView
    private let slider: NSSlider
    private let label: NSTextField

    var volume: Float = 0 {
        didSet {
            updateDisplay()
        }
    }

    var onVolumeChanged: ((Float) -> Void)?

    private static func icon(for volume: Float) -> NSImage? {
        let symbolName: String
        if volume == 0 {
            symbolName = "speaker.slash.fill"
        } else if volume < 0.5 {
            symbolName = "speaker.wave.1.fill"
        } else {
            symbolName = "speaker.wave.3.fill"
        }
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
    }

    override init(frame frameRect: NSRect) {
        iconView = NSImageView(image: Self.icon(for: 0) ?? NSImage())
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        slider = NSSlider(value: 0, minValue: 0, maxValue: 1, target: nil, action: nil)
        slider.controlSize = .mini
        slider.translatesAutoresizingMaskIntoConstraints = false

        label = NSTextField(labelWithString: "0%")
        label.font = .monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        label.alignment = .right
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: frameRect)

        wantsLayer = true
        slider.target = self
        slider.action = #selector(sliderChanged)
        layer?.cornerRadius = 6
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.7).cgColor

        addSubview(iconView)
        addSubview(slider)
        addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            slider.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            slider.centerYAnchor.constraint(equalTo: centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: 100),

            label.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 34),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func sliderChanged() {
        volume = slider.floatValue
        onVolumeChanged?(volume)
    }

    private func updateDisplay() {
        iconView.image = Self.icon(for: volume)
        let percentage = Int(volume * 100)
        label.stringValue = "\(percentage)%"
        if slider.floatValue != volume {
            slider.floatValue = volume
        }
    }
}
