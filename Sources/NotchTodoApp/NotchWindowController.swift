import AppKit
import SwiftUI

@MainActor
final class NotchWindowController {
    private let viewModel: TaskViewModel
    private let settings: AppSettingsState
    private let onSelectTaskFile: () -> Void
    private let onSetLaunchAtLogin: @MainActor @Sendable (Bool) -> Void
    private let onQuit: () -> Void
    private let presentation = NotchPresentationState()
    private var panel: NSPanel?
    private var screenInfo: BuiltInNotchScreen?
    private var collapseTask: Task<Void, Never>?
    private var animationTask: Task<Void, Never>?
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

    init(
        viewModel: TaskViewModel,
        settings: AppSettingsState,
        onSelectTaskFile: @escaping () -> Void,
        onSetLaunchAtLogin: @escaping @MainActor @Sendable (Bool) -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.settings = settings
        self.onSelectTaskFile = onSelectTaskFile
        self.onSetLaunchAtLogin = onSetLaunchAtLogin
        self.onQuit = onQuit
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
        animationTask?.cancel()
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
        panel.hasShadow = NotchLayout.usesWindowShadow
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovable = false
        panel.isReleasedWhenClosed = false

        let view = NotchPanelView(
            viewModel: viewModel,
            presentation: presentation,
            settings: settings,
            onHoverChanged: { [weak self] isInside in
                self?.handleHover(isInside)
            },
            onCompactTap: { [weak self] in
                self?.expandFromCompactTap()
            },
            onToggleLock: { [weak self] in
                self?.toggleLock()
            },
            onToggleTask: { [weak self] task in
                self?.viewModel.toggle(task)
            },
            onShowSettings: { [weak self] in
                self?.showSettings()
            },
            onShowTasks: { [weak self] in
                self?.presentation.showTasks()
            },
            onSelectTaskFile: { [weak self] in
                self?.selectTaskFile()
            },
            onReloadTasks: { [weak viewModel] in
                viewModel?.reloadTasks()
            },
            onOpenTaskFile: { [weak self] in
                self?.openTaskFile()
            },
            onRevealTaskFile: { [weak self] in
                self?.revealTaskFile()
            },
            onSetLaunchAtLogin: onSetLaunchAtLogin,
            onQuit: onQuit
        )
        panel.contentViewController = NSHostingController(rootView: view)
        return panel
    }

    private func showSettings() {
        presentation.showSettings()
        setExpanded(true)
        installClickMonitors()
    }

    private func selectTaskFile() {
        removeClickMonitors()
        onSelectTaskFile()
        if presentation.isShowingSettings {
            installClickMonitors()
        }
    }

    private func openTaskFile() {
        viewModel.openTaskFile()
    }

    private func revealTaskFile() {
        viewModel.revealTaskFile()
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

    private func expandFromCompactTap() {
        presentation.expandFromCompactTap()
        setExpanded(true)
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
        animationTask?.cancel()

        if expanded {
            if !presentation.isExpanded {
                presentation.isExpanded = true
            }
            guard !presentation.isContentVisible else { return }

            animationTask = Task { [weak self] in
                try? await Task.sleep(for: NotchAnimation.contentRevealDelay)
                guard !Task.isCancelled else { return }
                self?.presentation.isContentVisible = true
            }
        } else {
            guard presentation.isExpanded || presentation.isContentVisible else { return }

            presentation.isContentVisible = false
            presentation.resetForCollapse()
            removeClickMonitors()

            animationTask = Task { [weak self] in
                try? await Task.sleep(for: NotchAnimation.shapeCollapseDelay)
                guard !Task.isCancelled else { return }
                self?.presentation.isExpanded = false
            }
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
