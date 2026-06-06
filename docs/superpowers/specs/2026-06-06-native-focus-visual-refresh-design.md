# Native Focus Visual Refresh Design

## Goal

Polish the expanded notch panel into a restrained macOS-native interface that
helps the user identify the next task immediately. The refresh changes visual
hierarchy and display ordering only; Markdown parsing, file order, checkbox
writes, hover behavior, locking, and settings actions remain unchanged.

## Visual Direction

- Use near-black surfaces with low-contrast gray borders.
- Use the system font throughout.
- Reserve green for completion state and red for the quit action.
- Avoid gradients, decorative color, progress bars, shadows, and unnecessary
  badges.
- Keep the pixel Labubu in the task header as a small identity mark. It must
  not compete with task content.
- Preserve the current 360 by 420 point expanded panel and existing animation.

## Task Page

### Header

The header contains:

1. Pixel Labubu.
2. The title `今天`.
3. Completed and total count in subdued text.
4. Pin control.
5. Settings control.

Controls use small circular, low-contrast backgrounds. The header remains
compact and does not add a separate progress bar.

### Next Task

The first incomplete task in Markdown source order is the focused task.

It appears in a single bordered card containing:

- The label `接下来`.
- Its interactive checkbox.
- The task text.
- The text `还剩 N 项`, where `N` is the number of incomplete tasks.

The focused task is not removed from the underlying task model. Toggling its
checkbox updates the Markdown file through the existing write path, after
which the next incomplete task becomes focused.

If every task is complete, the focused card is replaced by a restrained
all-complete state. If the task list is empty, the existing empty state is
shown.

### Remaining Tasks

Other incomplete tasks appear below the label `稍后`. They preserve Markdown
source order and use compact, borderless rows.

Completed tasks appear below the label `已完成`. They preserve their relative
Markdown source order, remain interactive, and use reduced contrast with
strikethrough text. Clicking a completed task restores it and returns it to
the incomplete display according to source order.

This display grouping does not reorder or rewrite lines in the Markdown file.

### Scrolling

The area below the header remains scrollable as one unit so focused,
incomplete, and completed content can all be reached in long lists. Task text
continues to use the existing two-line limit.

## Settings Page

The settings page retains its existing actions and navigation:

- Return to tasks.
- Select or replace the Markdown file.
- Toggle launch at login.
- Quit Notch Todo.

File and launch-at-login controls use compact system-settings-style rows with
a subtle border and near-black fill. The selected file name is primary text;
its parent directory is secondary text.

The quit action is the only red control. It remains visually separated below
the settings rows.

## States and Errors

- File, bookmark, parsing, and write errors continue to use the existing
  behavior and messages.
- When no task file is selected, the file-selection action remains available
  directly from the task page.
- Opening settings continues to lock the panel open.
- Selecting a file continues to suspend outside-click handling while the
  system picker is visible.
- The compact notch state is not changed by this refresh.

## Architecture

The refresh stays inside the existing SwiftUI presentation layer:

- `TaskViewModel` remains the source of task and progress data.
- `NotchPanelView` derives the focused, remaining, and completed display groups
  without mutating the task array.
- Small task-page and settings-page view components may be extracted from
  `NotchPanelView.swift` only if needed to keep the view readable.
- AppKit window positioning, hover handling, and file synchronization are not
  modified.

## Verification

Automated tests cover:

- The first incomplete source-order task is selected as focused.
- Remaining incomplete tasks preserve source order.
- Completed tasks move to the displayed completed group while preserving
  relative source order.
- All-complete and empty lists have no focused task.
- Existing parser, file store, view model, animation, and settings tests remain
  green.

Manual verification covers:

- Visual hierarchy matches the approved mockup.
- Focused, remaining, and completed checkboxes all update the Markdown file.
- Long lists scroll without clipping the completed section.
- Task and settings pages fit the existing panel size.
- Hover, pin, outside-click, file picker, and quit behavior remain unchanged.

## Relationship to the Original Design

This document supersedes two presentation details in
`2026-06-06-notch-todo-design.md`:

- Settings are available inside the expanded notch panel, not through a menu
  bar item.
- Completed tasks are displayed in a bottom group rather than their original
  mixed position.

The Markdown file remains the source of truth, and its line order is never
changed by this visual grouping.
