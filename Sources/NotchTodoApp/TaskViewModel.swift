import Combine
import Foundation
import NotchTodoCore

@MainActor
final class TaskViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var errorMessage: String?

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

    var compactLabel: String {
        if errorMessage != nil {
            return "--/--"
        }
        return "\(completedCount)/\(totalCount)"
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
                    let message = error.localizedDescription
                    Task { @MainActor in
                        self?.showError(message)
                    }
                }
            }
        } catch {
            showError(error.localizedDescription)
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
            showError(error.localizedDescription)
        }
    }

    func showError(_ message: String) {
        errorMessage = message
    }

    private func reload() {
        guard let store else { return }
        do {
            apply(try store.load())
        } catch {
            tasks = []
            showError(error.localizedDescription)
        }
    }

    private func apply(_ tasks: [TaskItem]) {
        self.tasks = tasks
        errorMessage = nil
    }
}
