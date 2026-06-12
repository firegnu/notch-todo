# Desktop Widget Design

## Purpose

Add a native macOS desktop widget for Notch Todo without changing the existing
notch panel experience. The widget lets the user keep the task card on the
desktop while leaving the MacBook notch area available for another application.

The widget is an additive feature. Existing notch behavior remains the primary
application experience and must not regress.

## Assumptions

- The user still launches Notch Todo at least once to select or replace the
  Markdown task file.
- After a task file is selected, the desktop widget should be able to render
  without the main Notch Todo app running.
- The widget only needs to display tasks. It does not need the settings page or
  hover behavior.
- macOS 14 remains the minimum supported system.
- The selected Markdown file remains the source of truth.

## Scope

### Included

- A native macOS WidgetKit desktop widget.
- A card-style task display visually aligned with the current expanded notch
  task page.
- Read-only display of Markdown tasks:
  - title `今天`
  - completed and total count
  - focused next incomplete task
  - remaining incomplete tasks
  - completed tasks
  - empty and error states
- Shared task-file access setup so the widget can read the selected Markdown
  file when the main app is not running, if the platform permits it reliably.
- A fallback snapshot path if direct widget file access proves unreliable.
- Build, signing, and packaging updates needed to embed the widget extension in
  the app bundle.

### Excluded

- Changing current notch panel placement, hover, lock, settings, or animation.
- Replacing the current `NSPanel` notch UI with WidgetKit.
- Widget settings UI.
- Widget checkbox toggling in the first version.
- Widget Calendar agenda display in the first version.
- Creating, deleting, renaming, reordering, or editing task text.
- Supporting non-system desktop overlays that require the main app to stay
  running.

## Non-Regression Requirements

The existing application must keep working exactly as it does today:

- App launch still creates the notch panel on eligible built-in notched
  displays.
- Hover still expands the panel.
- Pin, settings, file selection, reload, reveal, open, quit, launch-at-login,
  and Calendar settings still work.
- Checkbox toggles in the notch panel still update the Markdown file.
- File monitoring still refreshes the notch panel after external file changes.
- Existing tests remain green, except for intentional additions.

The widget implementation should avoid touching `NotchWindowController` and
`NotchPanelView` except for extracting shared read-only presentation helpers if
that is clearly lower-risk than duplication. The first implementation should
prefer duplication inside the widget view over broad refactors.

## User Experience

The user installs or updates Notch Todo, launches it once, and selects a
Markdown task file as today. They can then add the Notch Todo widget from the
macOS widget gallery to the desktop.

When the main app is not running, the widget continues to appear on the desktop
as a system widget. It does not occupy the notch area and does not create an
AppKit floating window.

### Widget Card

The widget mirrors the current expanded task page, not the settings page:

- near-black background
- compact header with `今天`
- subdued completed/total count
- focused card for the first incomplete task
- `稍后` section for remaining incomplete tasks
- `已完成` section for completed tasks
- reduced contrast for completed task text

The widget should use WidgetKit families that fit the content safely:

- `systemMedium` as the primary family.
- `systemLarge` if the task list needs more vertical space.

The first version can omit `systemSmall` if the focused-card layout does not
fit without becoming cramped.

### Empty and Error States

The widget needs static states equivalent to the task page:

- no file selected
- task file missing
- permission lost
- invalid Markdown contract
- empty `## Tasks` section
- all tasks complete

If the widget cannot read the Markdown file, it should explain that Notch Todo
needs to be opened to refresh access. It should not show controls that cannot
work from the widget.

## Data Strategy

### Preferred Path: Direct Widget Read

The main app stores the selected task-file security-scoped bookmark in a
location shared with the widget extension. The widget resolves the bookmark,
starts security-scoped access, reads the Markdown file, parses it through
`NotchTodoCore`, and renders the result.

This best matches the user goal: the main app does not need to run for the
desktop widget to display the latest file contents when WidgetKit reloads it.

The direct-read path requires verification because WidgetKit extensions are
sandboxed and packaged separately from the main app. The implementation must
validate that the extension can reliably access the bookmark with the final app
bundle, entitlements, and signing approach.

### Fallback Path: Shared Snapshot

If direct widget file access is unreliable, the main app writes a compact
snapshot of the current task state into a widget-accessible shared container.
The widget reads that snapshot.

This fallback is less ideal because the widget can only show the latest state
known to the main app. However, it is simpler and lower-risk, and it still
allows the user to close the main app after the snapshot is written.

The fallback should be retained as a safety net even if direct-read works, so
the widget can show stale-but-useful data when bookmark access fails.

## Architecture

### NotchTodoCore

Keep Markdown parsing and task value types in `NotchTodoCore`, so both the main
app and widget can share the same parsing rules.

If needed, add a small read-only helper that converts parsed tasks into a
display model:

- completed count
- total count
- focused task
- remaining incomplete tasks
- completed tasks
- display state

This helper must not contain AppKit or WidgetKit dependencies.

### Main App

The main app remains responsible for:

- user-driven task file selection
- existing notch UI
- existing checkbox toggles
- existing file monitoring
- storing or refreshing widget-accessible bookmark data
- requesting WidgetKit timeline reloads after task file selection or task state
  changes

The main app should not need to stay alive for the widget to render.

### Widget Extension

Add a macOS WidgetKit extension that contains:

- widget entry type
- timeline provider
- read-only task loader
- SwiftUI widget card view
- sample preview data

The provider should generate one current entry and use a conservative reload
policy. The app can call WidgetKit reload APIs when it is running and knows the
file changed. When the app is not running, WidgetKit controls refresh timing.

### Build System

The current project is a Swift Package with a manually assembled app bundle.
WidgetKit requires an embedded app extension bundle. The implementation needs a
build approach that can produce:

```text
Notch Todo.app/
  Contents/
    MacOS/NotchTodo
    PlugIns/NotchTodoWidgetExtension.appex
```

The least risky implementation path is to add a generated or checked-in Xcode
project for app and widget packaging while keeping the existing SwiftPM package
as the source layout and test entry point. The current `swift test` workflow
should remain valid.

## Permissions and Signing

The widget extension needs its own entitlements. It should use the same App
Group as the main app for shared bookmark and snapshot data.

The direct-read path may require sandbox and file-access entitlement changes.
Those changes must be verified carefully because the current test suite
explicitly protects the main app from enabling sandbox without rechecking
Markdown file monitoring.

Ad-hoc local signing may be enough for local development, but final widget
discovery in macOS can be sensitive to bundle identifiers, entitlements,
embedded extension layout, and code signing. The implementation must verify the
installed app appears in the widget gallery.

## Testing

### Automated Tests

- Shared display model selects the first incomplete task as focused.
- Remaining incomplete tasks preserve Markdown source order.
- Completed tasks preserve relative source order.
- Empty and all-complete states are represented correctly.
- Error states map to widget-safe copy.
- Existing parser, store, view model, layout, Calendar, and Info.plist tests
  still pass.

### Manual Verification

- Existing notch panel still appears on launch.
- Existing hover, pin, settings, Calendar, and checkbox behavior still work.
- Installing the app makes the desktop widget available in the macOS widget
  gallery.
- Adding the widget to the desktop shows the task card.
- Quitting Notch Todo leaves the widget visible.
- With the main app not running, the widget can reload and display the selected
  Markdown file through direct-read access, or it falls back to the last
  snapshot with clear stale/error copy.
- Updating tasks through the notch panel refreshes the widget when the main app
  is running.

## Implementation Order

1. Add shared read-only task display model tests and implementation.
2. Add a local technical spike for widget bookmark access and App Group storage.
3. Add the WidgetKit extension and static widget view.
4. Wire the main app to store widget-accessible bookmark/snapshot data.
5. Update build packaging to embed and sign the widget extension.
6. Verify existing app behavior and widget discovery manually.

## Open Risks

- Widget extension direct access to the selected Markdown file may fail under
  the final sandbox/signing configuration.
- SwiftPM alone does not model macOS app extension targets, so packaging will
  likely need an Xcode project or equivalent manual extension build process.
- WidgetKit refresh timing is system-controlled when the main app is not
  running, so the widget cannot promise immediate updates after external file
  edits unless the main app is active or the system refreshes the timeline.

## Success Criteria

- The feature is additive: no existing notch behavior regresses.
- The desktop widget can be added from the macOS widget gallery.
- The widget shows the selected Markdown tasks without the notch panel running.
- If direct file access works, the widget reads the Markdown file itself.
- If direct file access fails, the widget displays the most recent snapshot and
  clear recovery copy.
