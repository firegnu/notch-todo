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
    private var notchWindowController: NotchWindowController?
    private var statusItem: NSStatusItem?
    private var taskFileStore: TaskFileStore?
    private var launchAtLoginItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()

        notchWindowController = NotchWindowController(viewModel: viewModel)
        restoreTaskFile()
        notchWindowController?.show()

        if taskFileStore == nil {
            viewModel.showError("请从菜单栏选择 Markdown 任务文件")
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        taskFileStore?.stopMonitoring()
        notchWindowController?.hide()
    }

    @objc private func selectTaskFile() {
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
            viewModel.showError("无法保存文件权限：\(error.localizedDescription)")
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            try launchAtLogin.setEnabled(!launchAtLogin.isEnabled)
            refreshLaunchAtLoginItem()
        } catch {
            viewModel.showError("无法更新登录启动设置：\(error.localizedDescription)")
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = LabubuIcon.image
        item.button?.image?.size = NSSize(width: 16, height: 16)
        item.button?.toolTip = "Notch Todo"

        let menu = NSMenu()
        let selectItem = menu.addItem(
            withTitle: "选择任务文件…",
            action: #selector(selectTaskFile),
            keyEquivalent: "o"
        )
        selectItem.target = self

        let loginItem = NSMenuItem(
            title: "登录时启动",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        loginItem.target = self
        menu.addItem(loginItem)
        launchAtLoginItem = loginItem
        refreshLaunchAtLoginItem()

        menu.addItem(.separator())
        let quitItem = menu.addItem(
            withTitle: "退出 Notch Todo",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self

        item.menu = menu
        statusItem = item
    }

    private func refreshLaunchAtLoginItem() {
        launchAtLoginItem?.state = launchAtLogin.isEnabled ? .on : .off
    }

    private func restoreTaskFile() {
        guard let bookmark = UserDefaults.standard.data(forKey: DefaultsKey.taskFileBookmark) else {
            return
        }

        do {
            useTaskFile(try TaskFileStore.resolveBookmark(bookmark))
        } catch {
            viewModel.showError("任务文件权限已失效，请重新选择文件")
        }
    }

    private func useTaskFile(_ url: URL) {
        taskFileStore?.stopMonitoring()
        let store = TaskFileStore(url: url)
        taskFileStore = store
        viewModel.use(store: store)
    }
}
