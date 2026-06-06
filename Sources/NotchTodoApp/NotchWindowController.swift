import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {
    private let viewModel: TaskViewModel
    private let presentation = NotchPresentationState()
    private var panel: NSPanel?
    private var screenInfo: BuiltInNotchScreen?
    private var collapseTask: Task<Void, Never>?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    private var isExpanded: Bool {
        presentation.isExpanded
    }

    private var isLocked: Bool {
        get { presentation.isLocked }
        set { presentation.isLocked = newValue }
    }

    init(viewModel: TaskViewModel) {
        self.viewModel = viewModel
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.show()
            }
        }
    }

    func show() {
        guard let screenInfo = BuiltInNotchScreen.current() else {
            hide()
            return
        }

        self.screenInfo = screenInfo
        presentation.notchWidth = screenInfo.notchWidth
        presentation.notchHeight = screenInfo.notchHeight
        if panel == nil {
            panel = makePanel()
        }
        updateFrame()
        panel?.orderFrontRegardless()
    }

    func hide() {
        collapseTask?.cancel()
        panel?.orderOut(nil)
        removeClickMonitors()
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = NotchLayout.windowLevel
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovable = false
        panel.isReleasedWhenClosed = false

        let view = NotchPanelView(
            viewModel: viewModel,
            presentation: presentation,
            onHoverChanged: { [weak self] isInside in
                self?.handleHover(isInside)
            },
            onToggleLock: { [weak self] in
                self?.toggleLock()
            },
            onToggleTask: { [weak self] task in
                self?.viewModel.toggle(task)
            }
        )
        panel.contentViewController = NSHostingController(rootView: view)
        return panel
    }

    private func handleHover(_ isInside: Bool) {
        collapseTask?.cancel()
        if isInside {
            setExpanded(true)
        } else if !isLocked {
            collapseTask = Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                self?.setExpanded(false)
            }
        }
    }

    private func toggleLock() {
        isLocked.toggle()
        setExpanded(isLocked || isExpanded)
        if isLocked {
            installClickMonitors()
        } else {
            removeClickMonitors()
        }
    }

    private func setExpanded(_ expanded: Bool) {
        guard expanded != isExpanded else { return }
        presentation.isExpanded = expanded
        if !expanded {
            isLocked = false
            removeClickMonitors()
        }
    }

    private func updateFrame() {
        guard let panel, let screenInfo else { return }
        panel.setFrame(
            NotchLayout.panelFrame(screenFrame: screenInfo.screen.frame),
            display: true
        )
    }

    private func installClickMonitors() {
        guard globalClickMonitor == nil, localClickMonitor == nil else { return }

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) {
            [weak self] _ in
            Task { @MainActor in
                self?.collapseIfClickIsOutside()
            }
        }
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) {
            [weak self] event in
            self?.collapseIfClickIsOutside()
            return event
        }
    }

    private func collapseIfClickIsOutside() {
        guard let panel else { return }
        let visibleFrame = isExpanded
            ? panel.frame
            : NotchLayout.compactFrame(
                screenFrame: screenInfo?.screen.frame ?? panel.frame,
                notchWidth: presentation.notchWidth,
                notchHeight: presentation.notchHeight
            )
        guard !visibleFrame.contains(NSEvent.mouseLocation) else { return }
        isLocked = false
        setExpanded(false)
    }

    private func removeClickMonitors() {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
    }
}
