import Foundation
import SwiftUI
import WidgetKit
import NotchTodoCore

struct NotchTodoWidgetEntry: TimelineEntry {
    let date: Date
    let content: NotchTodoWidgetContent
}

enum NotchTodoWidgetContent: Equatable {
    case tasks(TaskDisplayModel, isSnapshot: Bool)
    case message(symbol: String, title: String, message: String)
}

struct NotchTodoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NotchTodoWidgetEntry {
        NotchTodoWidgetEntry(
            date: Date(),
            content: .tasks(
                TaskDisplayModel(tasks: [
                    TaskItem(lineIndex: 1, text: "完成项目周报", isCompleted: false),
                    TaskItem(lineIndex: 2, text: "准备会议材料", isCompleted: false),
                    TaskItem(lineIndex: 3, text: "回复客户邮件", isCompleted: true),
                ]),
                isSnapshot: false
            )
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (NotchTodoWidgetEntry) -> Void
    ) {
        completion(
            NotchTodoWidgetEntry(
                date: Date(),
                content: WidgetTaskLoader().load()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<NotchTodoWidgetEntry>) -> Void
    ) {
        let entry = NotchTodoWidgetEntry(
            date: Date(),
            content: WidgetTaskLoader().load()
        )
        let refreshDate = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: entry.date
        ) ?? entry.date.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct WidgetTaskLoader {
    private let bookmarkStore: WidgetTaskFileBookmarkStore
    private let snapshotStore: WidgetTaskSnapshotStore

    init(
        bookmarkStore: WidgetTaskFileBookmarkStore = WidgetTaskFileBookmarkStore(
            defaults: WidgetSharedData.appGroupDefaults()
        ),
        snapshotStore: WidgetTaskSnapshotStore = WidgetTaskSnapshotStore(
            directoryURL: WidgetSharedData.appGroupContainerURL()
        )
    ) {
        self.bookmarkStore = bookmarkStore
        self.snapshotStore = snapshotStore
    }

    func load() -> NotchTodoWidgetContent {
        if let bookmark = bookmarkStore.loadBookmark() {
            do {
                let url = try TaskFileStore.resolveBookmark(bookmark)
                let store = TaskFileStore(url: url)
                return .tasks(
                    TaskDisplayModel(tasks: try store.load()),
                    isSnapshot: false
                )
            } catch {
                return snapshotContent() ?? .message(
                    symbol: "lock.trianglebadge.exclamationmark",
                    title: "需要重新授权",
                    message: "打开 Notch Todo 重新选择 Markdown 文件"
                )
            }
        }

        return snapshotContent() ?? .message(
            symbol: "doc.badge.plus",
            title: "请选择任务文件",
            message: "打开 Notch Todo 选择 Markdown 文件"
        )
    }

    private func snapshotContent() -> NotchTodoWidgetContent? {
        guard let snapshot = snapshotStore.loadSnapshot() else { return nil }
        return .tasks(TaskDisplayModel(tasks: snapshot.taskItems), isSnapshot: true)
    }
}

struct NotchTodoWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: NotchTodoWidgetEntry

    var body: some View {
        ZStack {
            Color.black
            content
                .padding(family == .systemLarge ? 16 : 14)
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.content {
        case let .tasks(model, isSnapshot):
            taskCard(model, isSnapshot: isSnapshot)
        case let .message(symbol, title, message):
            stateView(symbol: symbol, title: title, message: message)
        }
    }

    private func taskCard(
        _ model: TaskDisplayModel,
        isSnapshot: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                Text("今天")
                    .font(.headline)
                Spacer()
                Text("\(model.completedCount)/\(model.totalCount)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.56))
            }

            if model.tasks.isEmpty {
                stateView(
                    symbol: "checklist",
                    title: "暂无任务",
                    message: "在 Markdown 的 Tasks 区域添加任务"
                )
            } else if let focusedTask = model.focusedTask {
                focusedTaskCard(focusedTask, remainingCount: model.incompleteCount)

                if family == .systemLarge {
                    taskSections(model)
                } else {
                    compactRemainingSummary(model)
                }
            } else {
                stateView(
                    symbol: "checkmark.circle",
                    title: "今天的任务已完成",
                    message: isSnapshot ? "显示最近一次快照" : "做得不错"
                )
            }
        }
    }

    private func focusedTaskCard(
        _ task: TaskItem,
        remainingCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("接下来")
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.66))
                Text(task.text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.94))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            Text("还剩 \(remainingCount) 项")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.leading, 26)
        }
        .padding(12)
        .background(
            Color(red: 0.065, green: 0.065, blue: 0.075),
            in: RoundedRectangle(cornerRadius: 13)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func taskSections(_ model: TaskDisplayModel) -> some View {
        if !model.remainingTasks.isEmpty {
            sectionHeader("稍后")
            ForEach(model.remainingTasks.prefix(3)) { task in
                taskRow(task)
            }
        }

        if !model.completedTasks.isEmpty {
            sectionHeader("已完成")
            ForEach(model.completedTasks.prefix(3)) { task in
                taskRow(task)
            }
        }
    }

    @ViewBuilder
    private func compactRemainingSummary(_ model: TaskDisplayModel) -> some View {
        if let nextTask = model.remainingTasks.first {
            HStack(spacing: 8) {
                Text("稍后")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.38))
                Text(nextTask.text)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(task.isCompleted ? 0.32 : 0.66))
            Text(task.text)
                .font(.system(size: 12))
                .strikethrough(task.isCompleted)
                .foregroundStyle(.white.opacity(task.isCompleted ? 0.34 : 0.88))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            .white.opacity(task.isCompleted ? 0.025 : 0.045),
            in: RoundedRectangle(cornerRadius: 9)
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.65)
            .foregroundStyle(.white.opacity(0.38))
    }

    private func stateView(
        symbol: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white.opacity(0.52))
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.44))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotchTodoTaskWidget: Widget {
    let kind = WidgetSharedData.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotchTodoWidgetProvider()) { entry in
            NotchTodoWidgetView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .configurationDisplayName("Notch Todo")
        .description("显示今天的 Markdown 任务")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct NotchTodoWidgetBundle: WidgetBundle {
    var body: some Widget {
        NotchTodoTaskWidget()
    }
}
