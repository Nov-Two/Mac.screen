import AppKit
import WebKit

@MainActor
final class InAppBrowserWindowController: NSObject, WKUIDelegate, WKNavigationDelegate, WKDownloadDelegate {
    static let shared = InAppBrowserWindowController()

    private var windowController: NSWindowController?
    private var webView: WKWebView?
    private var downloadDestinations: [ObjectIdentifier: URL] = [:]

    func show(url: URL, title: String, onDownloadedResource: @escaping (URL) -> Void) {
        if let window = windowController?.window, let webView {
            window.title = title
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            self.onDownloadedResource = onDownloadedResource

            if webView.url != url {
                webView.load(URLRequest(url: url))
            }
            return
        }

        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1180, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentView = webView
        window.center()
        window.setFrameAutosaveName("MacScreenInAppBrowser")

        let windowController = NSWindowController(window: window)
        self.webView = webView
        self.windowController = windowController
        self.onDownloadedResource = onDownloadedResource

        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private var onDownloadedResource: ((URL) -> Void)?

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }

        return nil
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if navigationResponse.canShowMIMEType {
            decisionHandler(.allow)
        } else {
            decisionHandler(.download)
        }
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        do {
            let directory = try downloadsDirectory()
            let destinationURL = uniqueDownloadURL(
                for: sanitizedFilename(suggestedFilename),
                in: directory
            )
            downloadDestinations[ObjectIdentifier(download)] = destinationURL
            completionHandler(destinationURL)
        } catch {
            showDownloadError(error.localizedDescription)
            completionHandler(nil)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let destinationURL = downloadDestinations.removeValue(forKey: ObjectIdentifier(download)) else {
            return
        }

        onDownloadedResource?(destinationURL)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloadDestinations.removeValue(forKey: ObjectIdentifier(download))
        showDownloadError(error.localizedDescription)
    }

    private func downloadsDirectory() throws -> URL {
        let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)

        let directory = supportDirectory
            .appendingPathComponent("MacScreen", isDirectory: true)
            .appendingPathComponent("Downloads", isDirectory: true)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory
    }

    private func uniqueDownloadURL(for filename: String, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let sourceURL = URL(fileURLWithPath: filename)
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let pathExtension = sourceURL.pathExtension

        var destinationURL = directory.appendingPathComponent(filename)
        var index = 2
        while fileManager.fileExists(atPath: destinationURL.path) {
            let candidateName = pathExtension.isEmpty ? "\(baseName) \(index)" : "\(baseName) \(index).\(pathExtension)"
            destinationURL = directory.appendingPathComponent(candidateName)
            index += 1
        }

        return destinationURL
    }

    private func sanitizedFilename(_ filename: String) -> String {
        let illegalCharacters = CharacterSet(charactersIn: "/:")
        let cleaned = filename
            .components(separatedBy: illegalCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? "MacScreenDownload" : cleaned
    }

    private func showDownloadError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "下载失败"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }
}
