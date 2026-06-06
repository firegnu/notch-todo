import SwiftUI
import NotchTodoCore

@MainActor
final class NotchPresentationState: ObservableObject {
    @Published var isExpanded = false
    @Published var isLocked = false
    @Published var notchWidth: CGFloat = 180
    @Published var notchHeight: CGFloat = 32
}

struct NotchPanelView: View {
    @ObservedObject var viewModel: TaskViewModel
    @ObservedObject var presentation: NotchPresentationState

    let onHoverChanged: (Bool) -> Void
    let onToggleLock: () -> Void
    let onToggleTask: (TaskItem) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            ZStack(alignment: .top) {
                compactView
                    .opacity(presentation.isExpanded ? 0 : 1)
                    .scaleEffect(presentation.isExpanded ? 0.96 : 1)
                    .zIndex(presentation.isExpanded ? 0 : 1)

                expandedView
                    .opacity(presentation.isExpanded ? 1 : 0)
                    .scaleEffect(presentation.isExpanded ? 1 : 0.98, anchor: .top)
                    .allowsHitTesting(presentation.isExpanded)
                    .zIndex(presentation.isExpanded ? 1 : 0)
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
            .spring(response: 0.32, dampingFraction: 0.86),
            value: presentation.isExpanded
        )
    }

    private var compactView: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: NotchLayout.compactSideWidth)

            Color.clear
                .frame(width: presentation.notchWidth)

            Text(viewModel.compactLabel)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: NotchLayout.compactSideWidth)
        }
        .frame(height: presentation.notchHeight)
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
                    Image(systemName: presentation.isLocked ? "pin.fill" : "pin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 16)
                .padding(.top, max(12, presentation.notchHeight + 4))
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
