import SwiftUI
import NotchTodoCore

enum NotchAnimation {
    static let contentRevealDelay = Duration.milliseconds(70)
    static let shapeCollapseDelay = Duration.milliseconds(60)
    static let shapeResponse = 0.38
    static let shapeDampingFraction = 0.92
    static let contentDuration = 0.16
}

enum TaskRowStyle {
    static let cornerRadius: CGFloat = 9
    static let fontSize: CGFloat = 12.5
    static let focusedFontSize: CGFloat = 13
    static let focusedCardPadding: CGFloat = 13
    static let focusedCardCornerRadius: CGFloat = 13
    static let normalOpacity = 0.045
    static let hoverOpacity = 0.08
    static let completedOpacity = 0.025
}

enum TaskInteractionStyle {
    static let toggleDuration = 0.16
}

enum CompactDisplayStyle {
    static let activeOpacity = 1.0
    static let completeOpacity = 0.42
}

enum SettingsActionTitle {
    static let openTaskFile = "在默认 App 中打开"
    static let revealTaskFile = "在 Finder 中显示"
    static let reloadTasks = "重新加载任务"
}

enum SettingsLayout {
    static let scrollsWhenContentOverflows = true
}

struct TaskPanelStateContent {
    let symbol: String
    let title: String
    let message: String

    static let empty = TaskPanelStateContent(
        symbol: "checklist",
        title: "暂无任务",
        message: "在 Markdown 的 Tasks 区域添加任务"
    )
    static let complete = TaskPanelStateContent(
        symbol: "checkmark.circle",
        title: "今天的任务已完成",
        message: "做得不错"
    )
    static let error = TaskPanelStateContent(
        symbol: "exclamationmark.triangle",
        title: "无法读取任务",
        message: ""
    )
    static let fileMissing = TaskPanelStateContent(
        symbol: "doc.questionmark",
        title: "任务文件不存在",
        message: ""
    )
    static let noFileSelected = TaskPanelStateContent(
        symbol: "doc.badge.plus",
        title: "请选择任务文件",
        message: ""
    )
    static let permissionLost = TaskPanelStateContent(
        symbol: "lock.trianglebadge.exclamationmark",
        title: "需要重新授权",
        message: ""
    )
    static let markdownFormat = TaskPanelStateContent(
        symbol: "text.badge.xmark",
        title: "Tasks 区域格式错误",
        message: ""
    )
    static let writeConflict = TaskPanelStateContent(
        symbol: "arrow.triangle.2.circlepath",
        title: "任务已被外部修改",
        message: ""
    )
}

@MainActor
final class NotchPresentationState: ObservableObject {
    @Published var isExpanded = false
    @Published var isContentVisible = false
    @Published var isLocked = false
    @Published var isShowingSettings = false
    @Published var notchWidth: CGFloat = 180
    @Published var notchHeight: CGFloat = 32

    func showSettings() {
        isShowingSettings = true
        isLocked = true
    }

    func showTasks() {
        isShowingSettings = false
    }

    func expandFromCompactTap() {
        isExpanded = true
    }

    func resetForCollapse() {
        isShowingSettings = false
        isLocked = false
    }
}

struct NotchPanelView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoveredTaskID: String?

    @ObservedObject var viewModel: TaskViewModel
    @ObservedObject var presentation: NotchPresentationState
    @ObservedObject var settings: AppSettingsState

    let onHoverChanged: (Bool) -> Void
    let onCompactTap: () -> Void
    let onToggleLock: () -> Void
    let onToggleTask: (TaskItem) -> Void
    let onShowSettings: () -> Void
    let onShowTasks: () -> Void
    let onSelectTaskFile: () -> Void
    let onReloadTasks: () -> Void
    let onOpenTaskFile: () -> Void
    let onRevealTaskFile: () -> Void
    let onSetLaunchAtLogin: @MainActor @Sendable (Bool) -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                compactView
                    .opacity(presentation.isExpanded ? 0 : 1)
                    .scaleEffect(presentation.isExpanded ? 0.98 : 1, anchor: .top)
                    .zIndex(presentation.isExpanded ? 0 : 1)
                    .onTapGesture(perform: onCompactTap)
                    .animation(.easeOut(duration: 0.12), value: presentation.isExpanded)

                if presentation.isContentVisible {
                    expandedView
                        .transition(
                            .opacity.combined(
                                with: .scale(scale: 0.985, anchor: .top)
                            )
                        )
                        .zIndex(1)
                }
            }
            .foregroundStyle(.white)
            .frame(
                width: presentation.isExpanded
                    ? 360
                    : presentation.notchWidth + NotchLayout.compactSideWidth * 2,
                height: presentation.isExpanded ? 420 : presentation.notchHeight,
                alignment: .top
            )
            .clipped()
            .background(.black)
            .clipShape(
                UnevenRoundedRectangle(
                    bottomLeadingRadius: presentation.isExpanded ? 18 : 10,
                    bottomTrailingRadius: presentation.isExpanded ? 18 : 10
                )
            )
            .contentShape(Rectangle())
            .onHover(perform: onHoverChanged)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(
            .spring(
                response: NotchAnimation.shapeResponse,
                dampingFraction: NotchAnimation.shapeDampingFraction
            ),
            value: presentation.isExpanded
        )
        .animation(
            .easeOut(duration: NotchAnimation.contentDuration),
            value: presentation.isContentVisible
        )
    }

    private var compactView: some View {
        HStack(spacing: 0) {
            HStack(spacing: 2) {
                LabubuIconView(
                    size: 13,
                    celebrationTrigger: isAllComplete
                )
                Text(viewModel.compactLabel)
                    .font(
                        .system(
                            size: NotchLayout.compactSummaryFontSize,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
                .opacity(compactContentOpacity)
                .frame(width: NotchLayout.compactSideWidth)

            Color.clear
                .frame(width: presentation.notchWidth)

            Color.clear
                .frame(width: NotchLayout.compactSideWidth)
        }
        .frame(height: presentation.notchHeight)
    }

    private var expandedView: some View {
        VStack(spacing: 0) {
            expandedHeader

            Divider()
                .overlay(.white.opacity(0.15))

            Group {
                if presentation.isShowingSettings {
                    settingsView
                } else {
                    content
                }
            }
                .padding(12)

            Color.clear
                .frame(height: 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !presentation.isShowingSettings {
                        onToggleLock()
                    }
                }
        }
    }

    private var expandedHeader: some View {
        HStack(spacing: 10) {
            if presentation.isShowingSettings {
                headerButton(systemName: "chevron.left", action: onShowTasks)
                Text("设置")
                    .font(.headline)
            } else {
                LabubuIconView(
                    size: 18,
                    celebrationTrigger: isAllComplete
                )
                Text("今天")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.56))
                headerButton(
                    systemName: presentation.isLocked ? "pin.fill" : "pin",
                    action: onToggleLock
                )
                headerButton(systemName: "gearshape", action: onShowSettings)
            }

            if presentation.isShowingSettings {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, max(12, presentation.notchHeight + 4))
        .padding(.bottom, 12)
    }

    private func headerButton(
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(.white.opacity(0.07), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.68))
    }

    @ViewBuilder
    private var content: some View {
        if let error = viewModel.error {
            panelStateView(
                error.stateContent,
                message: error.message,
                actionTitle: error.recoveryActionTitle,
                action: recoveryAction(for: error)
            )
        } else if viewModel.tasks.isEmpty {
            panelStateView(TaskPanelStateContent.empty)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let focusedTask = viewModel.focusedTask {
                        focusedTaskCard(focusedTask)

                        if !viewModel.remainingTasks.isEmpty {
                            sectionHeader("稍后")
                                .padding(.top, 14)

                            ForEach(viewModel.remainingTasks) { task in
                                taskRow(task)
                            }
                        }
                    } else {
                        allCompleteView
                    }

                    if !viewModel.completedTasks.isEmpty {
                        sectionHeader("已完成")
                            .padding(.top, 14)

                        ForEach(viewModel.completedTasks) { task in
                            taskRow(task)
                        }
                    }
                }
            }
            .scrollIndicators(.never)
            .animation(
                reduceMotion
                    ? nil
                    : .easeOut(duration: TaskInteractionStyle.toggleDuration),
                value: viewModel.tasks
            )
        }
    }

    private func recoveryAction(for error: TaskPanelError) -> (() -> Void)? {
        switch error.kind {
        case .fileMissing, .noFileSelected, .permissionLost, .markdownFormat:
            onSelectTaskFile
        case .writeConflict:
            onReloadTasks
        case .generic:
            nil
        }
    }

    private func focusedTaskCard(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("接下来")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.7)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.42))

            Button {
                onToggleTask(task)
            } label: {
                HStack(alignment: .top, spacing: 11) {
                    checkbox(for: task)

                    Text(task.text)
                        .font(.system(size: TaskRowStyle.focusedFontSize, weight: .medium))
                        .foregroundStyle(.white.opacity(0.94))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("还剩 \(viewModel.incompleteCount) 项")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.leading, 27)
        }
        .padding(TaskRowStyle.focusedCardPadding)
        .background(
            Color(red: 0.065, green: 0.065, blue: 0.075),
            in: RoundedRectangle(cornerRadius: TaskRowStyle.focusedCardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: TaskRowStyle.focusedCardCornerRadius)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }

    private var allCompleteView: some View {
        panelStateView(TaskPanelStateContent.complete)
        .background(
            Color(red: 0.055, green: 0.055, blue: 0.063),
            in: RoundedRectangle(cornerRadius: 15)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func panelStateView(
        _ content: TaskPanelStateContent,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: content.symbol)
                .font(.system(size: 21, weight: .light))
                .foregroundStyle(
                    content.title == TaskPanelStateContent.error.title
                        ? Color.yellow.opacity(0.8)
                        : Color.white.opacity(0.52)
                )
            Text(content.title)
                .font(.system(size: 14, weight: .medium))
            Text(message ?? content.message)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.44))
                .multilineTextAlignment(.center)
                .lineLimit(3)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .padding(.top, 3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 22)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.65)
            .foregroundStyle(.white.opacity(0.38))
            .padding(.horizontal, 6)
            .padding(.bottom, 5)
    }

    private var settingsView: some View {
        ScrollView {
            VStack(spacing: 12) {
                Button(action: onSelectTaskFile) {
                    settingsRow(
                        icon: "doc.text",
                        title: settings.taskFileName,
                        subtitle: settings.taskFileDirectory,
                        trailing: "更换"
                    )
                }
                .buttonStyle(.plain)

                if settings.canOpenTaskFile {
                    Button(action: onOpenTaskFile) {
                        settingsRow(
                            icon: "arrow.up.right.square",
                            title: SettingsActionTitle.openTaskFile,
                            subtitle: settings.taskFileName,
                            trailing: "打开"
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onRevealTaskFile) {
                        settingsRow(
                            icon: "folder",
                            title: SettingsActionTitle.revealTaskFile,
                            subtitle: settings.taskFileName,
                            trailing: "显示"
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onReloadTasks) {
                        settingsRow(
                            icon: "arrow.clockwise",
                            title: SettingsActionTitle.reloadTasks,
                            subtitle: settings.taskFileName,
                            trailing: "刷新"
                        )
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    settingsIcon("power")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("登录时启动")
                            .font(.system(size: 14, weight: .medium))
                        Text("开机后自动显示任务")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        onSetLaunchAtLogin(!settings.launchAtLoginEnabled)
                    } label: {
                        Capsule()
                            .fill(
                                settings.launchAtLoginEnabled
                                    ? Color.green
                                    : Color.white.opacity(0.18)
                            )
                            .frame(width: 34, height: 20)
                            .overlay(alignment: settings.launchAtLoginEnabled ? .trailing : .leading) {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 16, height: 16)
                                    .padding(2)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("登录时启动")
                    .accessibilityValue(settings.launchAtLoginEnabled ? "已开启" : "已关闭")
                }
                .settingsCard()

                Button(action: onQuit) {
                    HStack {
                        Image(systemName: "power")
                        Text("退出 Notch Todo")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(.red.opacity(0.9))
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String,
        trailing: String
    ) -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Text(trailing)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
        }
        .settingsCard()
    }

    private func settingsIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .medium))
            .frame(width: 30, height: 30)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white.opacity(0.72))
    }

    private func taskRow(_ task: TaskItem) -> some View {
        Button {
            onToggleTask(task)
        } label: {
            HStack(alignment: .top, spacing: 11) {
                checkbox(for: task)

                Text(task.text)
                    .font(.system(size: TaskRowStyle.fontSize))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(.white.opacity(task.isCompleted ? 0.34 : 0.88))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(
                .white.opacity(taskRowBackgroundOpacity(for: task)),
                in: RoundedRectangle(cornerRadius: TaskRowStyle.cornerRadius)
            )
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
        .onHover { isHovered in
            hoveredTaskID = isHovered ? task.id : nil
        }
        .animation(.easeOut(duration: 0.12), value: hoveredTaskID)
    }

    private func taskRowBackgroundOpacity(for task: TaskItem) -> Double {
        if hoveredTaskID == task.id {
            return TaskRowStyle.hoverOpacity
        }
        return task.isCompleted
            ? TaskRowStyle.completedOpacity
            : TaskRowStyle.normalOpacity
    }

    private func checkbox(for task: TaskItem) -> some View {
        Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(
                task.isCompleted
                    ? Color.white.opacity(0.32)
                    : Color.white.opacity(0.66)
            )
            .scaleEffect(task.isCompleted ? 1 : 0.92)
            .opacity(task.isCompleted ? 1 : 0.86)
            .animation(
                reduceMotion
                    ? nil
                    : .easeOut(duration: TaskInteractionStyle.toggleDuration),
                value: task.isCompleted
            )
    }

    private var isAllComplete: Bool {
        viewModel.isAllComplete
    }

    private var compactContentOpacity: Double {
        isAllComplete
            ? CompactDisplayStyle.completeOpacity
            : CompactDisplayStyle.activeOpacity
    }
}

private extension View {
    func settingsCard() -> some View {
        padding(12)
            .background(
                Color(red: 0.055, green: 0.055, blue: 0.063),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.09), lineWidth: 1)
            }
    }
}
