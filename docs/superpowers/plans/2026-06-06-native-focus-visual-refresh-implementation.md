# Native Focus Visual Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the expanded notch panel around one focused incomplete task, a secondary incomplete list, and a subdued completed section.

**Architecture:** `TaskViewModel` exposes derived display groups without mutating Markdown source order. `NotchPanelView` consumes those groups and renders the approved native-focus task and settings layouts while preserving all existing actions and window behavior.

**Tech Stack:** Swift 6, SwiftUI, AppKit, XCTest

---

### Task 1: Task Display Groups

**Files:**
- Modify: `Sources/NotchTodoApp/TaskViewModel.swift`
- Modify: `Tests/NotchTodoAppTests/TaskViewModelTests.swift`

- [x] Add tests showing that the first incomplete task is focused, later incomplete tasks preserve order, completed tasks preserve relative order, and all-complete lists have no focused task.
- [x] Run `swift test --filter TaskViewModelTests` and verify the tests fail because the display-group properties do not exist.
- [x] Add `focusedTask`, `remainingTasks`, `completedTasks`, and `incompleteCount` as derived properties over `tasks`.
- [x] Run `swift test --filter TaskViewModelTests` and verify all view-model tests pass.

### Task 2: Native Focus Task Page

**Files:**
- Modify: `Sources/NotchTodoApp/NotchPanelView.swift`

- [x] Replace the flat task list with one scrollable hierarchy: focused card, `稍后` rows, and `已完成` rows.
- [x] Keep every checkbox wired to `onToggleTask`, retain the two-line task limit, and add a restrained all-complete state.
- [x] Change the task header title from `Today` to `今天` and use lower-contrast system controls.
- [x] Compile and run the full test suite.

### Task 3: Native Settings Polish

**Files:**
- Modify: `Sources/NotchTodoApp/NotchPanelView.swift`

- [x] Restyle settings rows with near-black fills, subtle borders, compact icons, and subdued secondary text.
- [x] Keep red exclusive to the quit action and preserve file selection, launch-at-login, and back navigation.
- [x] Run the complete test suite and confirm no compiler warnings.

### Task 4: App Verification

**Files:**
- No source changes expected.

- [x] Build `build/Notch Todo.app` with `scripts/build-app.sh`.
- [x] Verify the app bundle signature.
- [x] Restart the app and confirm the latest process is running.
- [x] Inspect the diff and confirm `.superpowers/` and `tomorrow.md` remain untracked.
