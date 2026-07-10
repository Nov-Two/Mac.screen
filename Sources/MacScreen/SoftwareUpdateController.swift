import AppKit
import Combine
import Sparkle
import SwiftUI

@MainActor
final class SoftwareUpdateController: ObservableObject {
    private let updaterController: SPUStandardUpdaterController?

    init() {
        guard Self.hasSparkleConfiguration else {
            updaterController = nil
            return
        }

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var updater: SPUUpdater? {
        updaterController?.updater
    }

    var canCheckForUpdates: Bool {
        updater?.canCheckForUpdates ?? true
    }

    func checkForUpdates() {
        guard let updaterController else {
            showMissingConfigurationAlert()
            return
        }

        updaterController.checkForUpdates(nil)
    }

    private func showMissingConfigurationAlert() {
        let alert = NSAlert()
        alert.messageText = "暂未配置自动更新"
        alert.informativeText = "生成 Sparkle EdDSA 密钥并在构建时提供 SPARKLE_PUBLIC_ED_KEY 后，就可以检查和安装新版本。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }

    private static var hasSparkleConfiguration: Bool {
        guard
            let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
            let publicKey = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        else {
            return false
        }

        return !feedURL.isEmpty
            && !publicKey.isEmpty
            && publicKey != "$(SPARKLE_PUBLIC_ED_KEY)"
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject private var viewModel: CheckForUpdatesViewModel
    private let updateController: SoftwareUpdateController

    init(updateController: SoftwareUpdateController) {
        self.updateController = updateController
        viewModel = CheckForUpdatesViewModel(updater: updateController.updater)
    }

    var body: some View {
        Button("检查更新...") {
            updateController.checkForUpdates()
        }
        .disabled(!viewModel.canCheckForUpdates)
        .pointingHandCursor()
    }
}

@MainActor
private final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates: Bool
    private var cancellable: AnyCancellable?

    init(updater: SPUUpdater?) {
        canCheckForUpdates = updater?.canCheckForUpdates ?? true

        cancellable = updater?
            .publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canCheckForUpdates in
                self?.canCheckForUpdates = canCheckForUpdates
            }
    }
}
