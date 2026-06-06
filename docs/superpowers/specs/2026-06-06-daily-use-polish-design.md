# Daily Use Polish Design

## Goal

Finish the first daily-use version with three restrained improvements:
lightweight checkbox feedback, consistent empty/error/completion states, and a
simple local installation script.

## Checkbox Feedback

- Checkbox state changes use a 160 ms ease-out scale and opacity transition.
- Task grouping changes animate with the same restrained timing.
- Animations are disabled when macOS Reduce Motion is enabled.
- No sound, confetti, bounce, or additional celebration effect is added.

## State Views

Empty, all-complete, and file-error states share one compact visual structure:

- One small SF Symbol.
- One concise title.
- One line of secondary guidance.
- An action button only when recovery requires file selection.

The states are:

- Empty: `暂无任务` / `在 Markdown 的 Tasks 区域添加任务`.
- Complete: `今天的任务已完成` / `做得不错`.
- Error: `无法读取任务` / the existing error message.

When an error is shown, `重新选择文件` remains available whether the previous
file URL is missing or stale.

## Installation

Add `scripts/install-app.sh` that:

1. Runs `scripts/build-app.sh`.
2. Stops a running Notch Todo process.
3. Replaces `/Applications/Notch Todo.app` with the newly built bundle.
4. Opens the installed application.

The script uses standard shell tools, quotes paths, exits on failure, and does
not implement updates, downloads, privilege escalation, or an installer UI.

## Verification

- Animation constants and state text are covered by focused tests.
- Existing tests remain green.
- The install script passes `bash -n`.
- The release bundle builds and verifies with `codesign`.
- The installed `/Applications/Notch Todo.app` launches successfully.
