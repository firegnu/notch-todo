# Notch Todo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS menu bar application that displays Markdown checklist progress beside the built-in MacBook notch and synchronizes checkbox changes back to the source file.

**Architecture:** A Swift Package executable separates pure Markdown parsing, security-scoped file persistence, observable task state, and AppKit notch-window management. SwiftUI renders the compact and expanded states while AppKit owns screen detection, floating-window behavior, file selection, and application lifecycle.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Foundation, ServiceManagement, XCTest

---

### Task 1: Swift Package and Markdown Parser

**Files:**
- Create: `Package.swift`
- Create: `Sources/NotchTodoCore/TaskItem.swift`
- Create: `Sources/NotchTodoCore/MarkdownTaskParser.swift`
- Test: `Tests/NotchTodoCoreTests/MarkdownTaskParserTests.swift`

- [ ] Write parser tests for valid tasks, section boundaries, missing/duplicate sections, empty sections, and minimal checkbox toggles.
- [ ] Run `swift test --filter MarkdownTaskParserTests` and verify RED because parser types do not exist.
- [ ] Implement immutable task records with source line indexes and a parser that only recognizes unindented `- [ ]`, `- [x]`, and `- [X]` markers inside one `## Tasks` section.
- [ ] Implement conflict-aware marker toggling that validates line index, task text, and previous completion state.
- [ ] Run `swift test --filter MarkdownTaskParserTests` and verify GREEN.

### Task 2: Task File Store

**Files:**
- Create: `Sources/NotchTodoCore/TaskFileStore.swift`
- Test: `Tests/NotchTodoCoreTests/TaskFileStoreTests.swift`

- [ ] Write tests using temporary files for load, toggle, conflicting external edits, and file-change observation.
- [ ] Run `swift test --filter TaskFileStoreTests` and verify RED.
- [ ] Implement UTF-8 reads, atomic writes, read-before-write conflict checks, and a dispatch-source file monitor.
- [ ] Add bookmark save/restore helpers behind APIs that can be exercised by the app target.
- [ ] Run `swift test --filter TaskFileStoreTests` and verify GREEN.

### Task 3: Observable Task Model

**Files:**
- Create: `Sources/NotchTodoApp/TaskViewModel.swift`
- Test: `Tests/NotchTodoAppTests/TaskViewModelTests.swift`

- [ ] Write tests for progress, successful toggles, retained completed tasks, external reloads, and rollback/error state.
- [ ] Run `swift test --filter TaskViewModelTests` and verify RED.
- [ ] Implement a main-actor view model that coordinates `TaskFileStore`, exposes task/progress/error state, and reloads after writes.
- [ ] Run `swift test --filter TaskViewModelTests` and verify GREEN.

### Task 4: Notch UI

**Files:**
- Create: `Sources/NotchTodoApp/NotchPanelView.swift`
- Create: `Sources/NotchTodoApp/NotchWindowController.swift`
- Create: `Sources/NotchTodoApp/BuiltInNotchScreen.swift`

- [ ] Add pure geometry tests for detecting a built-in notched screen and calculating compact/expanded frames.
- [ ] Run the geometry test and verify RED.
- [ ] Implement screen detection using `NSScreenNumber`, `CGDisplayIsBuiltin`, and `safeAreaInsets.top`.
- [ ] Implement a borderless non-activating `NSPanel` hosted with SwiftUI, compact progress UI, hover expansion, delayed collapse, header/background lock, outside-click collapse, task checkboxes, two-line truncation, and scrolling after eight rows.
- [ ] Run all tests and `swift build`.

### Task 5: Application Lifecycle and Menu Bar

**Files:**
- Create: `Sources/NotchTodoApp/NotchTodoApp.swift`
- Create: `Sources/NotchTodoApp/AppController.swift`
- Create: `Sources/NotchTodoApp/LaunchAtLoginController.swift`

- [ ] Implement an `NSApplicationDelegate` lifecycle with accessory activation policy.
- [ ] Add a status-item menu with Select Task File, Launch at Login, and Quit.
- [ ] Use `NSOpenPanel` for Markdown selection and persist a security-scoped bookmark in `UserDefaults`.
- [ ] Restore the selected file at launch and show an error state when restoration fails.
- [ ] Use `SMAppService.mainApp` for the login-item toggle, defaulting to disabled.
- [ ] Run all tests and `swift build`.

### Task 6: App Bundle, Documentation, and Verification

**Files:**
- Create: `scripts/build-app.sh`
- Create: `Resources/Info.plist`
- Create: `README.md`
- Create: `.gitignore`

- [ ] Add a script that release-builds the executable and assembles `build/Notch Todo.app`.
- [ ] Document the Markdown template, build/run commands, permissions, and current Command Line Tools limitation.
- [ ] Run `swift test`.
- [ ] Run `swift build -c release`.
- [ ] Run `scripts/build-app.sh` and inspect the generated bundle layout.
- [ ] Run `git diff --check` and review the implementation against all ten acceptance criteria.
