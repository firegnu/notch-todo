import AppKit
import NotchTodoCore
import UniformTypeIdentifiers

@MainActor
final class AppController: NSObject, NSApplicationDelegate {
    private enum DefaultsKey {
        static let taskFileBookmark = "taskFileBookmark"
    }

    private let viewModel = TaskViewModel()
    private let calendarAgenda = CalendarAgendaViewModel(
        provider: EventKitCalendarAgendaProvider()
    )
    private let launchAtLogin = LaunchAtLoginController()
    private lazy var settings = AppSettingsState(
        launchAtLoginEnabled: launchAtLogin.isEnabled
    )
    private var notchWindowController: NotchWindowController?
    private var taskFileStore: TaskFileStore?
    private var calendarAgendaRefreshTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        notchWindowController = NotchWindowController(
            viewModel: viewModel,
            calendarAgenda: calendarAgenda,
            settings: settings,
            onSelectTaskFile: { [weak self] in
                self?.selectTaskFile()
            },
            onEnableCalendarAgenda: { [weak self] in
                self?.enableCalendarAgenda()
            },
            onSelectCalendar: { [weak self] in
                self?.selectCalendarAgenda()
            },
            onReloadCalendarAgenda: { [weak self] in
                self?.calendarAgenda.reload()
            },
            onPanelExpanded: { [weak self] in
                self?.calendarAgenda.reloadIfStale(
                    staleAfter: CalendarAgendaRefreshPolicy.panelRefreshInterval
                )
            },
            onSetLaunchAtLogin: { [weak self] enabled in
                self?.setLaunchAtLogin(enabled)
            },
            onQuit: {
                NSApp.terminate(nil)
            }
        )
        restoreTaskFile()
        calendarAgenda.reload()
        startCalendarAgendaRefreshLoop()
        notchWindowController?.show()

        if taskFileStore == nil {
            viewModel.showError(.noFileSelected(message: "请选择 Markdown 任务文件"))
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        calendarAgendaRefreshTask?.cancel()
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

    private func enableCalendarAgenda() {
        Task { @MainActor in
            guard await calendarAgenda.requestAccessAndEnable() else { return }
            selectCalendarAgenda()
        }
    }

    private func selectCalendarAgenda() {
        Task { @MainActor in
            guard await calendarAgenda.requestAccessAndEnable() else { return }

            let calendars = calendarAgenda.availableCalendars
            guard !calendars.isEmpty else {
                calendarAgenda.showError("没有可用的 Calendar 日历")
                return
            }

            let popup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 320, height: 26))
            calendars.forEach { selection in
                popup.addItem(withTitle: selection.displayTitle)
            }
            if let selectedID = calendarAgenda.selectedCalendarID,
               let index = calendars.firstIndex(where: { $0.id == selectedID }) {
                popup.selectItem(at: index)
            }

            let alert = NSAlert()
            alert.messageText = "选择 Apple Calendar"
            alert.informativeText = "Notch Todo 只读显示所选日历中今天剩余的日程。"
            alert.accessoryView = popup
            alert.addButton(withTitle: "选择")
            alert.addButton(withTitle: "取消")

            guard alert.runModal() == .alertFirstButtonReturn else { return }
            calendarAgenda.selectCalendar(calendars[popup.indexOfSelectedItem])
        }
    }

    private func startCalendarAgendaRefreshLoop() {
        calendarAgendaRefreshTask?.cancel()
        calendarAgendaRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: CalendarAgendaRefreshPolicy.backgroundRefreshDuration)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.calendarAgenda.reloadIfStale(
                        staleAfter: CalendarAgendaRefreshPolicy.backgroundRefreshInterval
                    )
                }
            }
        }
    }
}
