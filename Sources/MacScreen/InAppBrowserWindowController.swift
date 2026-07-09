import AppKit
import WebKit

@MainActor
final class InAppBrowserWindowController: NSObject, NSWindowDelegate, WKUIDelegate, WKNavigationDelegate, WKDownloadDelegate {
    static let shared = InAppBrowserWindowController()

    private var windowController: NSWindowController?
    private var webView: WKWebView?
    private weak var backButton: NSButton?
    private weak var forwardButton: NSButton?
    private weak var reloadButton: NSButton?
    private weak var addressField: NSTextField?
    private var downloadDestinations: [ObjectIdentifier: URL] = [:]
    private var pendingRequestID: UUID?
    private var onDownloadedResource: ((URL) -> Void)?

    func show(url: URL, title: String, onDownloadedResource: @escaping (URL) -> Void) {
        let requestID = UUID()
        pendingRequestID = requestID
        closeCurrentWindow()
        self.onDownloadedResource = onDownloadedResource

        let dataStore = WKWebsiteDataStore.default()
        dataStore.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.pendingRequestID == requestID else { return }
                self.openFreshWindow(url: url, title: title)
            }
        }
    }

    private func openFreshWindow(url: URL, title: String) {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = false
        configuration.websiteDataStore = .nonPersistent()
        configuration.processPool = WKProcessPool()

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
        window.contentView = browserContentView(for: webView, initialURL: url)
        window.delegate = self
        window.center()

        let windowController = NSWindowController(window: window)
        self.webView = webView
        self.windowController = windowController

        windowController.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        updateBrowserControls()
    }

    private func browserContentView(for webView: WKWebView, initialURL: URL) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let toolbar = NSVisualEffectView()
        toolbar.material = .headerView
        toolbar.state = .active
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.distribution = .fill
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let backButton = toolbarButton(title: "‹", toolTip: "后退", action: #selector(goBack))
        let forwardButton = toolbarButton(title: "›", toolTip: "前进", action: #selector(goForward))
        let reloadButton = toolbarButton(title: "↻", toolTip: "刷新", action: #selector(reloadOrStop))
        let externalButton = toolbarButton(title: "浏览器", toolTip: "在默认浏览器中打开", action: #selector(openInDefaultBrowser), minimumWidth: 64)

        let addressField = NSTextField(string: initialURL.absoluteString)
        addressField.isEditable = false
        addressField.isSelectable = true
        addressField.placeholderString = "当前网址"
        addressField.bezelStyle = .roundedBezel
        addressField.backgroundColor = NSColor.controlBackgroundColor
        addressField.focusRingType = .none
        addressField.font = .systemFont(ofSize: 14, weight: .medium)
        addressField.lineBreakMode = .byTruncatingMiddle
        addressField.translatesAutoresizingMaskIntoConstraints = false
        addressField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        stack.addArrangedSubview(backButton)
        stack.addArrangedSubview(forwardButton)
        stack.addArrangedSubview(reloadButton)
        stack.addArrangedSubview(addressField)
        stack.addArrangedSubview(externalButton)

        toolbar.addSubview(stack)
        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(toolbar)
        container.addSubview(webView)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: container.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 52),

            stack.topAnchor.constraint(equalTo: toolbar.topAnchor),
            stack.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
            addressField.heightAnchor.constraint(equalToConstant: 30),
            addressField.widthAnchor.constraint(greaterThanOrEqualToConstant: 640),

            webView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        self.backButton = backButton
        self.forwardButton = forwardButton
        self.reloadButton = reloadButton
        self.addressField = addressField
        return container
    }

    private func toolbarButton(title: String, toolTip: String, action: Selector, minimumWidth: CGFloat = 34) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.font = .systemFont(ofSize: 13, weight: .medium)
        button.toolTip = toolTip
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: minimumWidth).isActive = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    private func closeCurrentWindow() {
        webView?.stopLoading()
        webView?.uiDelegate = nil
        webView?.navigationDelegate = nil
        windowController?.close()
        webView = nil
        windowController = nil
        backButton = nil
        forwardButton = nil
        reloadButton = nil
        addressField = nil
        downloadDestinations.removeAll()
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === windowController?.window else {
            return
        }

        webView?.stopLoading()
        webView?.uiDelegate = nil
        webView?.navigationDelegate = nil
        webView = nil
        windowController = nil
        backButton = nil
        forwardButton = nil
        reloadButton = nil
        addressField = nil
        downloadDestinations.removeAll()
    }

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

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateBrowserControls()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateBrowserControls()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateBrowserControls()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateBrowserControls()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        updateBrowserControls()
    }

    @objc private func goBack() {
        webView?.goBack()
    }

    @objc private func goForward() {
        webView?.goForward()
    }

    @objc private func reloadOrStop() {
        guard let webView else { return }

        if webView.isLoading {
            webView.stopLoading()
        } else {
            webView.reload()
        }
        updateBrowserControls()
    }

    @objc private func openInDefaultBrowser() {
        guard let url = webView?.url else { return }
        NSWorkspace.shared.open(url)
    }

    private func updateBrowserControls() {
        guard let webView else { return }

        backButton?.isEnabled = webView.canGoBack
        forwardButton?.isEnabled = webView.canGoForward
        reloadButton?.title = webView.isLoading ? "×" : "↻"
        reloadButton?.toolTip = webView.isLoading ? "停止" : "刷新"

        if let url = webView.url {
            addressField?.stringValue = url.absoluteString
        }

        if let title = webView.title, !title.isEmpty {
            windowController?.window?.title = title
        }
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
