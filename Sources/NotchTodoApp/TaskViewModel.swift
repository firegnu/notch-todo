import Combine
import AppKit
import Foundation
import NotchTodoCore

@MainActor
final class TaskViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var error: TaskPanelError?

    private var store: (any TaskFileStoring)?

    var completedCount: Int {
        tasks.lazy.filter(\.isCompleted).count
    }

    var totalCount: Int {
        tasks.count
    }

    var focusedTask: TaskItem? {
        tasks.first { !$0.isCompleted }
    }

    var remainingTasks: [TaskItem] {
        Array(tasks.lazy.filter { !$0.isCompleted }.dropFirst())
    }

    var completedTasks: [TaskItem] {
        tasks.filter(\.isCompleted)
    }

    var incompleteCount: Int {
        tasks.lazy.filter { !$0.isCompleted }.count
    }

    var isAllComplete: Bool {
        !tasks.isEmpty && incompleteCount == 0
    }

    var compactLabel: String {
        if error != nil {
            return "--/--"
        }
        if isAllComplete {
            return "✓"
        }
        return "\(completedCount)/\(totalCount)"
    }

    var errorMessage: String? {
        error?.message
    }

    func use(store: any TaskFileStoring) {
        self.store?.stopMonitoring()
        self.store = store
        reload()

        do {
            try store.startMonitoring { [weak self] result in
                switch result {
                case let .success(tasks):
                    Task { @MainActor in
                        self?.apply(tasks)
                    }
                case let .failure(error):
                    Task { @MainActor in
                        self?.showError(error)
                    }
                }
            }
        } catch {
            showError(error)
        }
    }

    func toggle(_ task: TaskItem) {
        guard let store else { return }
        let previousTasks = tasks

        if let index = tasks.firstIndex(of: task) {
            tasks[index] = TaskItem(
                lineIndex: task.lineIndex,
                text: task.text,
                isCompleted: !task.isCompleted
            )
        }

        do {
            apply(try store.toggle(task))
        } catch {
            tasks = previousTasks
            showError(error)
        }
    }

    func reloadTasks() {
        reload()
    }

    func openTaskFile() {
        guard let url = existingTaskFileURL() else { return }
        NSWorkspace.shared.open(url)
    }

    func revealTaskFile() {
        guard let url = existingTaskFileURL() else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func showError(_ message: String) {
        error = .generic(message: message)
    }

    func showError(_ panelError: TaskPanelError) {
        error = panelError
    }

    private func reload() {
        guard let store else { return }
        do {
            apply(try store.load())
        } catch {
            tasks = []
            showError(error)
        }
    }

    private func apply(_ tasks: [TaskItem]) {
        self.tasks = tasks
        error = nil
    }

    private func existingTaskFileURL() -> URL? {
        guard let url = store?.url else { return nil }
        guard FileManager.default.fileExists(atPath: url.path) else {
            showError(.fileMissing(message: "任务文件不存在，请重新选择文件"))
            return nil
        }
        return url
    }

    private func showError(_ error: Swift.Error) {
        self.error = TaskPanelError.classified(from: error)
    }
}
