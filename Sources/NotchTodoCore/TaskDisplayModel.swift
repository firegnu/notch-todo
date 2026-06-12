public struct TaskDisplayModel: Equatable, Sendable {
    public let tasks: [TaskItem]

    public init(tasks: [TaskItem]) {
        self.tasks = tasks
    }

    public var completedCount: Int {
        tasks.lazy.filter(\.isCompleted).count
    }

    public var totalCount: Int {
        tasks.count
    }

    public var focusedTask: TaskItem? {
        tasks.first { !$0.isCompleted }
    }

    public var remainingTasks: [TaskItem] {
        Array(tasks.lazy.filter { !$0.isCompleted }.dropFirst())
    }

    public var completedTasks: [TaskItem] {
        tasks.filter(\.isCompleted)
    }

    public var incompleteCount: Int {
        tasks.lazy.filter { !$0.isCompleted }.count
    }

    public var isAllComplete: Bool {
        !tasks.isEmpty && incompleteCount == 0
    }
}
