import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {
    private let viewModel: TaskViewModel
    private var panel: NSPanel?
    private var screenInfo: BuiltInNotchScreen?
    private var collapseTask: Task<Void, Never>?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    private(set) var isExpanded = false
    private(set) var isLocked = false

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
        if panel == nil {
            panel = makePanel()
        }
        updateContent()
        updateFrame(animated: false)
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
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        return panel
    }

    private func updateContent() {
        guard let panel, let screenInfo else { return }

        let view = NotchPanelView(
            viewModel: viewModel,
            notchWidth: screenInfo.notchWidth,
            notchHeight: screenInfo.notchHeight,
            isExpanded: isExpanded,
            isLocked: isLocked,
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
        updateContent()
    }

    private func setExpanded(_ expanded: Bool) {
        guard expanded != isExpanded else { return }
        isExpanded = expanded
        if !expanded {
            isLocked = false
            removeClickMonitors()
        }
        updateContent()
        updateFrame(animated: true)
    }

    private func updateFrame(animated: Bool) {
        guard let panel, let screenInfo else { return }
        let frame = isExpanded
            ? NotchLayout.expandedFrame(screenFrame: screenInfo.screen.frame)
            : NotchLayout.compactFrame(
                screenFrame: screenInfo.screen.frame,
                notchWidth: screenInfo.notchWidth,
                notchHeight: screenInfo.notchHeight
            )
        panel.setFrame(frame, display: true, animate: animated)
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
        guard let panel, !panel.frame.contains(NSEvent.mouseLocation) else { return }
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
