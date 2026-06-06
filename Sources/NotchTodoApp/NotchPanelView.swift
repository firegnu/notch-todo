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
            Button(action: onToggleLock) {
                HStack {
                    LabubuIconView(
                        size: 18,
                        celebrationTrigger: isAllComplete
                    )
                    Text("Today")
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

    private var isAllComplete: Bool {
        !viewModel.tasks.isEmpty
            && viewModel.completedCount == viewModel.totalCount
    }
}
