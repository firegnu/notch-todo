# In-Panel Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the menu bar item and provide file selection, launch-at-login, and quit controls inside the expanded notch panel.

**Architecture:** `AppController` remains the owner of macOS operations and exposes their current state through a small observable settings model. `NotchWindowController` coordinates settings presentation with the existing panel lock, while `NotchPanelView` renders either tasks or a compact settings page.

**Tech Stack:** Swift 6, SwiftUI, AppKit, ServiceManagement, Swift Testing

---

### Task 1: Settings Presentation State

**Files:**
- Modify: `Sources/NotchTodoApp/NotchPanelView.swift`
- Create: `Tests/NotchTodoAppTests/NotchPresentationStateTests.swift`

- [x] Write tests proving that opening settings locks the panel and collapsing returns to the task view.
- [x] Run the focused tests and verify they fail because the settings state API does not exist.
- [x] Add `isShowingSettings`, `showSettings()`, `showTasks()`, and `resetForCollapse()` to `NotchPresentationState`.
- [x] Run the focused tests and verify they pass.

### Task 2: Settings Model and Panel UI

**Files:**
- Create: `Sources/NotchTodoApp/AppSettingsState.swift`
- Modify: `Sources/NotchTodoApp/NotchPanelView.swift`
- Modify: `Sources/NotchTodoApp/NotchWindowController.swift`

- [x] Add a focused settings state test for displaying the selected file name and path.
- [x] Run the focused test and verify it fails because `AppSettingsState` does not exist.
- [x] Implement the observable settings state.
- [x] Add a gear button, back navigation, selected-file card, launch-at-login toggle, and quit button to the expanded panel.
- [x] Ensure opening settings locks the panel and closing/collapsing restores the task view.
- [x] Run the app test target and verify it passes.

### Task 3: Remove Menu Bar and Wire System Actions

**Files:**
- Modify: `Sources/NotchTodoApp/AppController.swift`
- Modify: `Sources/NotchTodoApp/NotchWindowController.swift`

- [x] Remove `NSStatusItem` creation and menu selectors.
- [x] Pass select-file, launch-at-login, and quit actions into the notch panel.
- [x] Update the settings state after bookmark restoration, file selection, and launch-at-login changes.
- [x] Replace the first-launch menu bar error with an in-panel file selection prompt.
- [x] Run the complete test suite.

### Task 4: End-to-End Verification

**Files:**
- No source changes expected.

- [x] Build the release app bundle with `scripts/build-app.sh`.
- [x] Verify the bundle signature.
- [x] Restart the app and confirm the notch panel process is running without a menu bar item implementation.
- [x] Inspect `git diff` and confirm `tomorrow.md` remains untracked and no credentials or unrelated files are included.
