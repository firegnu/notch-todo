# Daily Use Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add restrained checkbox feedback, consistent task states, and a one-command local installation flow.

**Architecture:** Presentation constants and reusable state content stay in `NotchPanelView.swift`; task and file behavior remain unchanged. A small shell script composes the existing build script with replacement and launch steps for `/Applications`.

**Tech Stack:** Swift 6, SwiftUI, XCTest, Bash

---

### Task 1: Animation and State Contracts

**Files:**
- Modify: `Sources/NotchTodoApp/NotchPanelView.swift`
- Modify: `Tests/NotchTodoAppTests/NotchLayoutTests.swift`

- [x] Add failing tests for the 160 ms checkbox animation and concise empty, complete, and error titles.
- [x] Add the style constants and state content definitions.
- [x] Run focused tests until they pass.

### Task 2: Checkbox and State UI

**Files:**
- Modify: `Sources/NotchTodoApp/NotchPanelView.swift`

- [x] Respect `accessibilityReduceMotion` and animate checkbox and task regrouping only when allowed.
- [x] Render empty, complete, and error states through one compact reusable view.
- [x] Keep file reselection available from the error state.
- [x] Run the complete test suite.

### Task 3: Installation Script

**Files:**
- Create: `scripts/install-app.sh`
- Modify: `README.md`

- [x] Add a shell syntax test that fails because the install script does not exist.
- [x] Implement build, stop, replace, and open steps with quoted paths.
- [x] Document `./scripts/install-app.sh` in the README.
- [x] Run `bash -n scripts/install-app.sh`.

### Task 4: Final Verification

**Files:**
- No source changes expected.

- [x] Run the complete Swift test suite.
- [x] Run the installer and verify `/Applications/Notch Todo.app`.
- [x] Verify the installed bundle signature and running process.
- [x] Confirm `.superpowers/` and `tomorrow.md` remain untracked.
