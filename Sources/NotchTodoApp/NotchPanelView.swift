import SwiftUI
import NotchTodoCore

struct NotchPanelView: View {
    @ObservedObject var viewModel: TaskViewModel

    let notchWidth: CGFloat
    let notchHeight: CGFloat
    let isExpanded: Bool
    let isLocked: Bool
    let onHoverChanged: (Bool) -> Void
    let onToggleLock: () -> Void
    let onToggleTask: (TaskItem) -> Void

    var body: some View {
        Group {
            if isExpanded {
                expandedView
            } else {
                compactView
            }
        }
        .foregroundStyle(.white)
        .background(.black)
        .clipShape(
            UnevenRoundedRectangle(
                bottomLeadingRadius: isExpanded ? 18 : 10,
                bottomTrailingRadius: isExpanded ? 18 : 10
            )
        )
        .onHover(perform: onHoverChanged)
    }

    private var compactView: some View {
        HStack(spacing: 8) {
            Color.clear
                .frame(width: notchWidth)

            Text(viewModel.compactLabel)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .padding(.trailing, 10)
        }
        .frame(height: max(32, notchHeight))
    }

    private var expandedView: some View {
        VStack(spacing: 0) {
            Button(action: onToggleLock) {
                HStack {
                    Text("🌙 Today")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Image(systemName: isLocked ? "pin.fill" : "pin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .padding(.top, max(12, notchHeight + 4))
                .padding(.bottom, 12)
            }
            .buttonStyle(.plain)

            Divider()
                .overlay(.white.opacity(0.15))

            content
                .padding(12)

            Color.clear
                .frame(height: 6)
                .contentShape(Rectangle())
                .onTapGesture(perform: onToggleLock)
        }
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
}
