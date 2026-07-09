import AppKit
import SwiftUI

struct MainWindowAccessor: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.attach(to: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.attach(to: nsView.window)
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        private weak var attachedWindow: NSWindow?

        func attach(to window: NSWindow?) {
            guard let window, attachedWindow !== window else { return }
            attachedWindow = window
            window.identifier = .macScreenMainWindow
            window.delegate = self
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            sender.orderOut(nil)
            return false
        }
    }
}

extension NSUserInterfaceItemIdentifier {
    static let macScreenMainWindow = NSUserInterfaceItemIdentifier("MacScreenMainWindow")
}
