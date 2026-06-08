# Apple Calendar Agenda Display Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Read events from one selected Apple Calendar calendar and display today's remaining agenda separately from Markdown tasks.

**Architecture:** Keep Markdown tasks and Calendar agenda as separate state streams. Add a small EventKit-backed provider for permission, calendar listing, and today's events; add a `CalendarAgendaViewModel` owned by `AppController`; pass it into `NotchPanelView` for separate agenda rendering and settings controls.

**Tech Stack:** Swift 6, SwiftUI, AppKit, EventKit, XCTest, macOS 14.

---

## File Structure

- Create `Sources/NotchTodoApp/CalendarAgendaItem.swift`
  - Pure value types for displayed calendar events and selectable calendars.
  - No EventKit dependency, so tests can run without Calendar permission.
- Create `Sources/NotchTodoApp/CalendarAgendaProvider.swift`
  - `CalendarAgendaProviding` protocol.
  - `EventKitCalendarAgendaProvider` implementation.
  - EventKit permission and query code live here only.
- Create `Sources/NotchTodoApp/CalendarAgendaViewModel.swift`
  - Holds enabled state, selected calendar, today's events, and calendar-specific errors.
  - Persists selection in `UserDefaults`.
- Modify `Sources/NotchTodoApp/AppController.swift`
  - Owns the calendar view model.
  - Presents the one-calendar chooser using `NSAlert` + `NSPopUpButton`.
  - Wires Calendar actions into `NotchWindowController`.
- Modify `Sources/NotchTodoApp/NotchWindowController.swift`
  - Passes `CalendarAgendaViewModel` and Calendar callbacks into `NotchPanelView`.
- Modify `Sources/NotchTodoApp/NotchPanelView.swift`
  - Adds a separate “日程” section below Markdown tasks.
  - Adds settings rows for enabling Calendar access and choosing one calendar.
- Modify `Resources/Info.plist`
  - Add `NSCalendarsFullAccessUsageDescription`.
- Modify `Tests/NotchTodoAppTests/`
  - Add tests for formatting, view model state transitions, permission failure, selected calendar persistence, and layout constants.

---

## Task 1: Calendar Display Models

**Files:**
- Create: `Sources/NotchTodoApp/CalendarAgendaItem.swift`
- Test: `Tests/NotchTodoAppTests/CalendarAgendaItemTests.swift`

- [x] **Step 1: Write failing formatting tests**

Create `Tests/NotchTodoAppTests/CalendarAgendaItemTests.swift`:

```swift
import Foundation
import XCTest
@testable import NotchTodoApp

final class CalendarAgendaItemTests: XCTestCase {
    func testTimedEventFormatsTimeRange() {
        let calendar = Calendar(identifier: .gregorian)
        let start = DateComponents(calendar: calendar, year: 2026, month: 6, day: 8, hour: 14, minute: 5).date!
        let end = DateComponents(calendar: calendar, year: 2026, month: 6, day: 8, hour: 15, minute: 30).date!

        let item = CalendarAgendaItem(
            id: "event-1",
            title: "产品评审",
            startDate: start,
            endDate: end,
            isAllDay: false
        )

        XCTAssertEqual(item.timeText, "14:05-15:30")
    }

    func testAllDayEventFormatsAsAllDay() {
        let item = CalendarAgendaItem(
            id: "event-2",
            title: "发布日",
            startDate: Date(),
            endDate: Date(),
            isAllDay: true
        )

        XCTAssertEqual(item.timeText, "全天")
    }
}
```

- [x] **Step 2: Run test to verify RED**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter CalendarAgendaItemTests'
```

Expected: compile fails because `CalendarAgendaItem` does not exist.

- [x] **Step 3: Add model implementation**

Create `Sources/NotchTodoApp/CalendarAgendaItem.swift`:

```swift
import Foundation

struct CalendarAgendaItem: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool

    var timeText: String {
        if isAllDay {
            return "全天"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startDate))-\(formatter.string(from: endDate))"
    }
}

struct CalendarAgendaSelection: Equatable, Identifiable {
    let id: String
    let title: String
    let sourceTitle: String

    var displayTitle: String {
        sourceTitle.isEmpty ? title : "\(sourceTitle) / \(title)"
    }
}
```

- [x] **Step 4: Run model tests**

Run the same `CalendarAgendaItemTests` command.

Expected: tests pass.

---

## Task 2: Calendar Agenda Provider

**Files:**
- Create: `Sources/NotchTodoApp/CalendarAgendaProvider.swift`
- Test: compile through `swift test --filter CalendarAgendaItemTests`

- [x] **Step 1: Add provider protocol and errors**

Create `Sources/NotchTodoApp/CalendarAgendaProvider.swift`:

```swift
import EventKit
import Foundation

enum CalendarAgendaError: Error, Equatable {
    case accessDenied
    case calendarMissing
}

protocol CalendarAgendaProviding: AnyObject {
    func hasFullAccess() -> Bool
    func requestFullAccess() async throws -> Bool
    func calendars() -> [CalendarAgendaSelection]
    func events(for calendarID: String, on date: Date, now: Date) throws -> [CalendarAgendaItem]
}
```

- [x] **Step 2: Add EventKit implementation**

Append to `CalendarAgendaProvider.swift`:

```swift
final class EventKitCalendarAgendaProvider: CalendarAgendaProviding {
    private let store = EKEventStore()

    func hasFullAccess() -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            return true
        case .authorized:
            return true
        default:
            return false
        }
    }

    func requestFullAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            store.requestFullAccessToEvents { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func calendars() -> [CalendarAgendaSelection] {
        store.calendars(for: .event)
            .filter { !$0.isSubscribed }
            .sorted { left, right in
                left.title.localizedCompare(right.title) == .orderedAscending
            }
            .map {
                CalendarAgendaSelection(
                    id: $0.calendarIdentifier,
                    title: $0.title,
                    sourceTitle: $0.source?.title ?? ""
                )
            }
    }

    func events(for calendarID: String, on date: Date, now: Date) throws -> [CalendarAgendaItem] {
        guard let calendar = store.calendar(withIdentifier: calendarID) else {
            throw CalendarAgendaError.calendarMissing
        }

        let currentCalendar = Calendar.current
        let start = currentCalendar.startOfDay(for: date)
        let end = currentCalendar.date(byAdding: .day, value: 1, to: start) ?? date
        let predicate = store.predicateForEvents(
            withStart: start,
            end: end,
            calendars: [calendar]
        )

        return store.events(matching: predicate)
            .filter { $0.isAllDay || $0.endDate >= now }
            .sorted { $0.startDate < $1.startDate }
            .map {
                CalendarAgendaItem(
                    id: $0.eventIdentifier,
                    title: $0.title,
                    startDate: $0.startDate,
                    endDate: $0.endDate,
                    isAllDay: $0.isAllDay
                )
            }
    }
}
```

- [x] **Step 3: Compile**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter CalendarAgendaItemTests'
```

Expected: tests pass and EventKit code compiles.

---

## Task 3: Calendar Agenda View Model

**Files:**
- Create: `Sources/NotchTodoApp/CalendarAgendaViewModel.swift`
- Test: `Tests/NotchTodoAppTests/CalendarAgendaViewModelTests.swift`

- [x] **Step 1: Write failing state tests**

Create `Tests/NotchTodoAppTests/CalendarAgendaViewModelTests.swift`:

```swift
import Foundation
import XCTest
@testable import NotchTodoApp

@MainActor
final class CalendarAgendaViewModelTests: XCTestCase {
    func testSelectCalendarLoadsEventsAndPersistsSelection() {
        let defaults = UserDefaults(suiteName: "CalendarAgendaViewModelTests.select")!
        defaults.removePersistentDomain(forName: "CalendarAgendaViewModelTests.select")
        let provider = MockCalendarAgendaProvider()
        provider.availableCalendars = [
            CalendarAgendaSelection(id: "work", title: "工作", sourceTitle: "iCloud")
        ]
        provider.eventsByCalendarID["work"] = [
            CalendarAgendaItem(
                id: "event",
                title: "站会",
                startDate: Date(timeIntervalSince1970: 100),
                endDate: Date(timeIntervalSince1970: 200),
                isAllDay: false
            )
        ]
        let viewModel = CalendarAgendaViewModel(provider: provider, defaults: defaults)

        viewModel.selectCalendar(provider.availableCalendars[0], now: Date(timeIntervalSince1970: 50))

        XCTAssertTrue(viewModel.isEnabled)
        XCTAssertEqual(viewModel.selectedCalendarTitle, "iCloud / 工作")
        XCTAssertEqual(viewModel.events.map(\.title), ["站会"])
        XCTAssertEqual(defaults.string(forKey: CalendarAgendaDefaultsKey.selectedCalendarID), "work")
    }

    func testLoadSelectedCalendarMissingShowsError() {
        let defaults = UserDefaults(suiteName: "CalendarAgendaViewModelTests.missing")!
        defaults.removePersistentDomain(forName: "CalendarAgendaViewModelTests.missing")
        defaults.set(true, forKey: CalendarAgendaDefaultsKey.isEnabled)
        defaults.set("missing", forKey: CalendarAgendaDefaultsKey.selectedCalendarID)
        let provider = MockCalendarAgendaProvider()
        let viewModel = CalendarAgendaViewModel(provider: provider, defaults: defaults)

        viewModel.reload(now: Date())

        XCTAssertEqual(viewModel.errorMessage, "已选择的日历不可用，请重新选择")
        XCTAssertTrue(viewModel.events.isEmpty)
    }
}

private final class MockCalendarAgendaProvider: CalendarAgendaProviding {
    var fullAccess = true
    var availableCalendars: [CalendarAgendaSelection] = []
    var eventsByCalendarID: [String: [CalendarAgendaItem]] = [:]

    func hasFullAccess() -> Bool { fullAccess }
    func requestFullAccess() async throws -> Bool { fullAccess }
    func calendars() -> [CalendarAgendaSelection] { availableCalendars }
    func events(for calendarID: String, on date: Date, now: Date) throws -> [CalendarAgendaItem] {
        guard let events = eventsByCalendarID[calendarID] else {
            throw CalendarAgendaError.calendarMissing
        }
        return events
    }
}
```

- [x] **Step 2: Run RED**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter CalendarAgendaViewModelTests'
```

Expected: compile fails because `CalendarAgendaViewModel` and `CalendarAgendaDefaultsKey` do not exist.

- [x] **Step 3: Add view model implementation**

Create `Sources/NotchTodoApp/CalendarAgendaViewModel.swift` with enabled state, selected calendar, reload, selection persistence, and access request.

- [x] **Step 4: Run view model tests**

Run the same `CalendarAgendaViewModelTests` command.

Expected: tests pass.

---

## Task 4: Settings Wiring and Calendar Selection

**Files:**
- Modify: `Sources/NotchTodoApp/AppController.swift`
- Modify: `Sources/NotchTodoApp/NotchWindowController.swift`
- Modify: `Sources/NotchTodoApp/NotchPanelView.swift`
- Test: `Tests/NotchTodoAppTests/NotchLayoutTests.swift`

- [x] **Step 1: Add layout tests for copy**

Add assertions:

```swift
XCTAssertEqual(CalendarAgendaCopy.sectionTitle, "日程")
XCTAssertEqual(CalendarAgendaCopy.enableTitle, "启用 Apple Calendar")
XCTAssertEqual(CalendarAgendaCopy.chooseCalendarTitle, "选择日历")
```

- [x] **Step 2: Run RED**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter NotchLayoutTests'
```

Expected: compile fails because `CalendarAgendaCopy` does not exist.

- [x] **Step 3: Add UI constants and settings rows**

Add `CalendarAgendaCopy` to `NotchPanelView.swift`, pass `CalendarAgendaViewModel` into `NotchPanelView`, and add settings rows:

- disabled: `启用 Apple Calendar`
- enabled without calendar: `选择日历`
- enabled with calendar: selected calendar display + `更换`

- [x] **Step 4: Wire actions**

Wire callbacks:

- `onEnableCalendarAgenda`
- `onSelectCalendar`
- `onReloadCalendarAgenda`

`AppController` requests access and presents `NSAlert` with `NSPopUpButton` for available calendars.

- [x] **Step 5: Run layout tests**

Run `swift test --filter NotchLayoutTests`.

Expected: pass.

---

## Task 5: Agenda Display Section

**Files:**
- Modify: `Sources/NotchTodoApp/NotchPanelView.swift`
- Test: `Tests/NotchTodoAppTests/NotchLayoutTests.swift`

- [x] **Step 1: Add layout constants test**

Add assertions that the agenda section stays subtle:

```swift
XCTAssertEqual(CalendarAgendaStyle.maxVisibleRows, 3)
XCTAssertLessThanOrEqual(CalendarAgendaStyle.emptyOpacity, 0.45)
```

- [x] **Step 2: Run RED**

Run `swift test --filter NotchLayoutTests`.

Expected: compile fails because `CalendarAgendaStyle` does not exist.

- [x] **Step 3: Add section rendering**

In `NotchPanelView.content`, render Calendar separately from Markdown tasks:

- Header: `日程`
- Rows: `timeText + title`
- Empty state: `今日日程为空`
- Error state: short error text
- Hidden if Calendar is disabled

- [x] **Step 4: Run layout tests**

Run `swift test --filter NotchLayoutTests`.

Expected: pass.

---

## Task 6: Bundle Privacy Configuration and Verification

**Files:**
- Modify: `Resources/Info.plist`
- Test: `Tests/NotchTodoAppTests/InfoPlistTests.swift`

- [x] **Step 1: Add failing plist test**

Create `Tests/NotchTodoAppTests/InfoPlistTests.swift`:

```swift
import Foundation
import XCTest

final class InfoPlistTests: XCTestCase {
    func testCalendarFullAccessUsageDescriptionExists() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Resources/Info.plist")
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        let value = try XCTUnwrap(plist["NSCalendarsFullAccessUsageDescription"] as? String)
        XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
```

- [x] **Step 2: Run RED**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter InfoPlistTests'
```

Expected: fail because the key is missing.

- [x] **Step 3: Add plist key**

Add:

```xml
<key>NSCalendarsFullAccessUsageDescription</key>
<string>用于在面板中只读显示今天的 Apple Calendar 日程。</string>
```

- [x] **Step 4: Run full tests and install**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test'
./scripts/install-app.sh
```

Expected: tests pass, app installs and launches.

---

## Task 7: Calendar Agenda Refresh Policy

**Files:**
- Modify: `Sources/NotchTodoApp/CalendarAgendaViewModel.swift`
- Modify: `Sources/NotchTodoApp/AppController.swift`
- Modify: `Sources/NotchTodoApp/NotchWindowController.swift`
- Test: `Tests/NotchTodoAppTests/CalendarAgendaViewModelTests.swift`

- [x] **Step 1: Add refresh policy tests**

Calendar agenda should refresh when stale, skip recent panel-triggered reloads, and use these intervals:

```swift
XCTAssertEqual(CalendarAgendaRefreshPolicy.panelRefreshInterval, 60)
XCTAssertEqual(CalendarAgendaRefreshPolicy.backgroundRefreshInterval, 300)
```

- [x] **Step 2: Verify RED**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter CalendarAgendaViewModelTests'
```

Expected: compile fails before `CalendarAgendaRefreshPolicy` and `reloadIfStale` exist.

- [x] **Step 3: Implement throttled reload**

Add `CalendarAgendaRefreshPolicy`, `lastReloadAt`, and `reloadIfStale(date:now:staleAfter:)` to `CalendarAgendaViewModel`.

- [x] **Step 4: Wire runtime triggers**

`NotchWindowController.setExpanded(true)` calls `onPanelExpanded`, and `AppController` starts a background loop that sleeps for 5 minutes and then calls `reloadIfStale`.

- [x] **Step 5: Verify**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter CalendarAgendaViewModelTests'
```

Expected: tests pass.

---

## Self-Review

- Spec coverage: The plan implements Calendar as a separate read-only display stream, not Markdown sync.
- Scope check: No event creation, no date parsing, no reverse sync, no account management.
- Privacy: Uses EventKit full access because reading events requires full access; usage string is added to `Info.plist`.
- Testability: Pure formatting and view-model behavior are unit-tested without Calendar permission; EventKit adapter is covered by compile and manual app testing.
- Refresh policy: App startup, calendar selection, manual reload, panel expansion with 60-second throttling, and 5-minute background polling are covered.
- Known manual verification: Calendar permission prompt, selecting a real calendar, selected calendar removed from macOS Calendar accounts.
