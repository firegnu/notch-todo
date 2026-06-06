# Notch Todo Design

## Purpose

Notch Todo is a lightweight macOS application that keeps a previously prepared
task list visible near the MacBook notch. It addresses a narrow problem: tasks
planned in another tool or file are easy to forget the next day if the user
does not reopen that tool.

The application does not calculate dates or manage planning. The selected
Markdown file is the single source of truth.

## Scope

### Included

- Native macOS application built with SwiftUI and AppKit.
- Minimum supported system: macOS 14 Sonoma.
- Display only on the built-in display when that display has a notch.
- First-launch selection of a Markdown task file.
- Persistent access to the selected file across application launches.
- Compact progress display near the notch.
- Hover-to-expand task panel.
- Interactive checkboxes that update the selected Markdown file.
- Automatic refresh when the file changes externally.
- Configurable launch at login.
- Menu bar controls for file selection, launch-at-login, and quitting.

### Excluded

- Creating, deleting, renaming, reordering, or editing task text.
- Date calculation or automatic selection of tomorrow's tasks.
- Calendar, Reminders, Todoist, Notion, or other task-service integrations.
- Nested tasks, priorities, due dates, or rich task metadata.
- Display on external monitors or displays without a notch.

## User Experience

### Compact State

While the application is running, a compact indicator remains visible beside
the built-in display's notch:

```text
🌙 3/5
```

The first number is the completed task count and the second is the total task
count. The MVP uses fixed `🌙` and `✨` state emoji rather than adding an emoji
preference.

State variants:

- In progress: `🌙 3/5`
- All complete: `✨ 5/5`
- Empty task section: `🌙 0/0`
- File error: `⚠️ --/--`

### Expanded State

Moving the pointer into the notch interaction area expands a panel below the
notch. The panel displays every task in source-file order:

```text
┌──────────────────────────┐
│ 🌙 Today             3/5 │
├──────────────────────────┤
│ ☑ 完成项目周报            │
│ ☐ 修改登录页面            │
│ ☑ 准备会议材料            │
└──────────────────────────┘
```

- Each task has an interactive checkbox.
- Completed tasks remain in their original position.
- Completed task text uses a strikethrough and reduced opacity.
- A task may occupy at most two lines; overflow is truncated.
- Lists longer than approximately eight visible rows scroll inside the panel.
- Moving the pointer out closes a temporary expansion after about 300 ms.
- Clicking the panel header or empty panel background locks it open.
- Clicking the header/background again, or clicking outside, unlocks and
  closes it.
- Clicking a task checkbox never changes the panel's lock state.

The only task operation available in this panel is toggling completion.

## Markdown Contract

The application reads first-level checklist items from the `## Tasks` section.
The section ends at the next level-two heading or at the end of the file.

Recommended template:

```md
# Tomorrow

## Tasks

- [ ] 完成项目周报
- [ ] 准备会议材料
- [x] 回复客户邮件
```

Parsing rules:

- Recognize `- [ ]`, `- [x]`, and `- [X]`.
- Read only unindented checklist items in the `## Tasks` section.
- Ignore checklists elsewhere in the document.
- Preserve source order.
- Preserve headings, blank lines, unrelated content, and task text.
- Treat a missing or duplicate `## Tasks` section as a format error.
- Treat an existing, valid `## Tasks` section with no tasks as an empty list.

When a checkbox is toggled, only the checkbox marker on the corresponding
source line changes. No other source content is reformatted.

## File Selection and Persistence

On first launch, the application presents the macOS file picker and asks the
user to select a Markdown file. It stores a security-scoped bookmark so that it
can recover access after relaunch.

The menu bar includes:

- Select Task File
- Launch at Login
- Quit

Selecting another file replaces the stored bookmark and reloads the task list.
Launch at Login is disabled by default. Quitting stops the notch UI and file
monitor completely so another notch application can run without interference.

## Synchronization

### External Changes

`TaskFileStore` monitors the selected file. After an external change, it reads
and parses the latest file contents, then updates the task list and progress.
Self-generated file events are handled through the same reload path.

### Checkbox Changes

When the user toggles a checkbox:

1. Keep the previous UI state available for rollback.
2. Read the latest file contents.
3. Parse the latest `## Tasks` section.
4. Identify the source task using its last known line location and content.
5. Abort if the task can no longer be identified unambiguously.
6. Change only the checkbox marker.
7. Write the complete updated content using atomic replacement.
8. Parse the saved content and refresh the UI.

This read-before-write flow reduces the chance of overwriting an external
change. The UI may update optimistically, but it must roll back if the write
fails or conflicts.

## Architecture

### AppController

Owns application lifecycle, menu bar commands, launch-at-login configuration,
and shutdown.

### NotchWindowController

Uses AppKit to identify the built-in notched display, position a borderless
floating window, and manage compact, hover-expanded, and locked-expanded
states. It does not migrate the window to an external display.

### TaskFileStore

Owns the security-scoped bookmark, file access, file monitoring, atomic writes,
and file-level errors.

### MarkdownTaskParser

Parses the `## Tasks` section into task records with source locations. It also
produces a minimally changed document when a task completion marker is toggled.
The parser has no UI or file-system responsibilities.

### TaskViewModel

Coordinates file state and views. It exposes tasks, completed and total counts,
loading state, and user-facing errors. It handles checkbox requests and
rollback.

### SwiftUI Views

Render the compact progress indicator, expanded task panel, task rows, empty
state, and error state.

## State Flow

```text
External file change
  -> TaskFileStore reads file
  -> MarkdownTaskParser parses tasks
  -> TaskViewModel updates tasks and progress
  -> SwiftUI refreshes compact and expanded views

Checkbox click
  -> TaskViewModel requests toggle
  -> TaskFileStore reads latest file
  -> MarkdownTaskParser validates and changes one marker
  -> TaskFileStore atomically writes file
  -> saved file is parsed
  -> TaskViewModel refreshes or rolls back on failure
```

## Error Handling

- Missing or moved file: show `⚠️ --/--` and offer file reselection through
  the menu bar.
- Expired permission: attempt bookmark recovery; if recovery fails, request
  file selection again.
- Invalid Markdown contract: show a concise format error and the expected
  template; do not modify the file.
- Ambiguous or conflicting checkbox update: preserve the latest external file,
  roll back the checkbox UI, and show an error.
- Write failure: roll back the checkbox UI and show an error.
- Temporarily unavailable file: keep the application running and allow reload
  or reselection.
- No built-in notched display: do not show the floating notch interface; keep
  the menu bar controls available.

## Testing

### Parser Tests

- Parse incomplete and completed tasks.
- Ignore checklists outside `## Tasks`.
- Stop at the next level-two heading.
- Preserve unrelated content when toggling a marker.
- Handle empty sections.
- Reject missing and duplicate task sections.
- Reject ambiguous updates without modifying content.

### Store Tests

- Restore a selected file using a bookmark.
- Reload after an external file change.
- Write a checkbox update atomically.
- Surface missing-file, permission, and write errors.
- Avoid overwriting a conflicting external edit.

### View Model Tests

- Calculate progress correctly.
- Keep completed tasks in source order.
- Roll back optimistic state after a failed write.
- Reflect externally changed task state.

### Manual macOS Verification

- Window aligns with the built-in MacBook notch.
- External displays receive no notch UI.
- Hover, delayed close, click-to-lock, and outside-click behavior work.
- Long lists scroll and long task text truncates after two lines.
- Launch-at-login setting persists.
- Quit removes the notch UI and stops monitoring.

## Acceptance Criteria

1. The first launch allows selection of a Markdown file, and later launches
   restore access to it.
2. The compact notch indicator displays the correct emoji and completed/total
   progress.
3. Hovering expands the task panel, leaving closes it after a short delay, and
   clicking can lock and unlock the panel.
4. The expanded panel displays all tasks and an interactive checkbox for each.
5. Toggling a checkbox switches the source Markdown marker between `[ ]` and
   `[x]`.
6. A completed task remains in place and is visibly completed.
7. External file changes automatically update the panel and progress.
8. Long task lists scroll and task text uses no more than two display lines.
9. The floating UI appears only on a built-in display with a notch.
10. Launch at Login can be enabled or disabled, and Quit fully stops the
    application.
