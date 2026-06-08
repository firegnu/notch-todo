import AppKit
import NotchTodoCore
import UniformTypeIdentifiers

@MainActor
final class AppController: NSObject, NSApplicationDelegate {
    private enum DefaultsKey {
        static let taskFileBookmark = "taskFileBookmark"
    }

    private let viewModel = TaskViewModel()
    private let launchAtLogin = LaunchAtLoginController()
    private lazy var settings = AppSettingsState(
        launchAtLoginEnabled: launchAtLogin.isEnabled
    )
    private var notchWindowController: NotchWindowController?
    private var taskFileStore: TaskFileStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        notchWindowController = NotchWindowController(
            viewModel: viewModel,
            settings: settings,
            onSelectTaskFile: { [weak self] in
                self?.selectTaskFile()
            },
            onSetLaunchAtLogin: { [weak self] enabled in
                self?.setLaunchAtLogin(enabled)
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        restoreTaskFile()
        notchWindowController?.show()

        if taskFileStore == nil {
            viewModel.showError(.noFileSelected(message: "请选择 Markdown 任务文件"))
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        taskFileStore?.stopMonitoring()
        notchWindowController?.hide()
    }

    private func selectTaskFile() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.title = "选择任务 Markdown 文件"
        panel.prompt = "选择"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText,
            .plainText,
        ]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let bookmark = try TaskFileStore.makeBookmark(for: url)
            UserDefaults.standard.set(bookmark, forKey: DefaultsKey.taskFileBookmark)
            useTaskFile(url)
        } catch {
            viewModel.showError(.permissionLost(message: "无法保存文件权限：\(error.localizedDescription)"))
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLogin.setEnabled(enabled)
            settings.setLaunchAtLoginEnabled(launchAtLogin.isEnabled)
        } catch {
            settings.setLaunchAtLoginEnabled(launchAtLogin.isEnabled)
            viewModel.showError(.generic(message: "无法更新登录启动设置：\(error.localizedDescription)"))
        }
    }

    private func restoreTaskFile() {
        guard let bookmark = UserDefaults.standard.data(forKey: DefaultsKey.taskFileBookmark) else {
            return
        }

        do {
            useTaskFile(try TaskFileStore.resolveBookmark(bookmark))
        } catch {
            viewModel.showError(.permissionLost(message: "任务文件权限已失效，请重新选择文件"))
        }
    }

    private func useTaskFile(_ url: URL) {
        taskFileStore?.stopMonitoring()
        let store = TaskFileStore(url: url)
        taskFileStore = store
        settings.setTaskFile(url)
        viewModel.use(store: store)
    }
}
