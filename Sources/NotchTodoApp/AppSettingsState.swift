import Combine
import Foundation

@MainActor
final class AppSettingsState: ObservableObject {
    @Published private(set) var taskFileURL: URL?
    @Published private(set) var launchAtLoginEnabled: Bool

    init(launchAtLoginEnabled: Bool) {
        self.launchAtLoginEnabled = launchAtLoginEnabled
    }

    var taskFileName: String {
        taskFileURL?.lastPathComponent ?? "未选择任务文件"
    }

    var taskFileDirectory: String {
        guard let taskFileURL else {
            return "请选择一个 Markdown 文件"
        }

        let directory = taskFileURL.deletingLastPathComponent().path
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if directory == home {
            return "~"
        }
        if directory.hasPrefix(home + "/") {
            return "~" + directory.dropFirst(home.count)
        }
        return directory
    }

    func setTaskFile(_ url: URL) {
        taskFileURL = url
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        launchAtLoginEnabled = enabled
    }
}
