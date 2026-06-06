import SwiftUI
import NotchTodoCore

enum NotchAnimation {
    static let contentRevealDelay = Duration.milliseconds(70)
    static let shapeCollapseDelay = Duration.milliseconds(60)
    static let shapeResponse = 0.38
    static let shapeDampingFraction = 0.92
    static let contentDuration = 0.16
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

    func resetForCollapse() {
        isShowingSettings = false
        isLocked = false
    }
}

struct NotchPanelView: View {
    @ObservedObject var viewModel: TaskViewModel
    @ObservedObject var presentation: NotchPresentationState
    @ObservedObject var settings: AppSettingsState

    let onHoverChanged: (Bool) -> Void
    let onToggleLock: () -> Void
    let onToggleTask: (TaskItem) -> Void
    let onShowSettings: () -> Void
    let onShowTasks: () -> Void
    let onSelectTaskFile: () -> Void
    let onSetLaunchAtLogin: @MainActor @Sendable (Bool) -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                compactView
                    .opacity(presentation.isExpanded ? 0 : 1)
                    .scaleEffect(presentation.isExpanded ? 0.98 : 1, anchor: .top)
                    .zIndex(presentation.isExpanded ? 0 : 1)
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
                Text("Today")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
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
                .background(.white.opacity(0.09), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.78))
    }

    @ViewBuilder
    private var content: some View {
        if let error = viewModel.errorMessage {
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(error)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                if settings.taskFileURL == nil {
                    Button("选择任务文件", action: onSelectTaskFile)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.tasks.isEmpty {
            Text("暂无任务")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.tasks) { task in
                        taskRow(task)
                    }
                }
            }
            .scrollIndicators(.visible)
        }
    }

    private var settingsView: some View {
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

            Spacer(minLength: 4)

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
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white.opacity(0.85))
    }

    private func taskRow(_ task: TaskItem) -> some View {
        Button {
            onToggleTask(task)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(task.isCompleted ? .green : .white.opacity(0.85))

                Text(task.text)
                    .font(.system(size: 14))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(.white.opacity(task.isCompleted ? 0.48 : 0.92))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
    }

    private var isAllComplete: Bool {
        !viewModel.tasks.isEmpty
            && viewModel.completedCount == viewModel.totalCount
    }
}

private extension View {
    func settingsCard() -> some View {
        padding(12)
            .background(
                .white.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 14)
            )
    }
}
