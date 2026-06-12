# Desktop Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native macOS desktop WidgetKit widget that displays the selected Markdown tasks without changing existing notch panel behavior.

**Architecture:** Keep task parsing and read-only display grouping in `NotchTodoCore` so both the main app and widget use the same task rules. The main app continues to own file selection and notch UI, and it mirrors the selected security-scoped bookmark plus a task snapshot into an App Group container. A new SwiftPM-built WidgetKit executable is embedded manually as `Contents/PlugIns/NotchTodoWidgetExtension.appex` by the existing build script.

**Tech Stack:** Swift 6, SwiftUI, WidgetKit, AppIntents-compatible WidgetKit timeline APIs, AppKit, SwiftPM, XCTest, macOS 14.

---

## File Structure

- Create `Sources/NotchTodoCore/TaskDisplayModel.swift`
  - Pure read-only grouping for focused, remaining, completed, and counts.
- Create `Tests/NotchTodoCoreTests/TaskDisplayModelTests.swift`
  - Tests source-order grouping and all-complete/empty behavior.
- Create `Sources/NotchTodoCore/WidgetSharedData.swift`
  - App Group constants, bookmark storage, and JSON snapshot storage.
- Create `Tests/NotchTodoCoreTests/WidgetSharedDataTests.swift`
  - Tests bookmark and snapshot round trips through injected stores.
- Modify `Sources/NotchTodoApp/TaskViewModel.swift`
  - Add an optional state-change callback, defaulting to `nil`.
- Modify `Sources/NotchTodoApp/AppController.swift`
  - Mirror bookmarks/snapshots into widget storage and request timeline reloads.
- Create `Sources/NotchTodoWidgetExtension/NotchTodoWidget.swift`
  - Timeline provider, loader, entry, and widget card view.
- Modify `Package.swift`
  - Add a `NotchTodoWidgetExtension` executable product and target.
- Create `Resources/NotchTodoWidgetExtension-Info.plist`
  - Widget extension bundle metadata and extension point.
- Create `Resources/NotchTodoWidgetExtension.entitlements`
  - Widget sandbox, App Group, and security-scoped bookmark entitlements.
- Modify `Resources/NotchTodo.entitlements`
  - Add the shared App Group without enabling app sandbox.
- Modify `Tests/NotchTodoAppTests/InfoPlistTests.swift`
  - Verify app/widget entitlements and widget extension plist.
- Modify `scripts/build-app.sh`
  - Build and embed the widget `.appex`, then sign extension and host app.

---

### Task 1: Shared Task Display Model

**Files:**
- Create: `Sources/NotchTodoCore/TaskDisplayModel.swift`
- Create: `Tests/NotchTodoCoreTests/TaskDisplayModelTests.swift`

- [ ] **Step 1: Write the failing tests**

Create `Tests/NotchTodoCoreTests/TaskDisplayModelTests.swift`:

```swift
import XCTest
@testable import NotchTodoCore

final class TaskDisplayModelTests: XCTestCase {
    func testFocusedTaskIsFirstIncompleteTaskInSourceOrder() {
        let tasks = [
            TaskItem(lineIndex: 1, text: "done first", isCompleted: true),
            TaskItem(lineIndex: 2, text: "next", isCompleted: false),
            TaskItem(lineIndex: 3, text: "later", isCompleted: false),
            TaskItem(lineIndex: 4, text: "done second", isCompleted: true),
        ]

        let model = TaskDisplayModel(tasks: tasks)

        XCTAssertEqual(model.completedCount, 2)
        XCTAssertEqual(model.totalCount, 4)
        XCTAssertEqual(model.incompleteCount, 2)
        XCTAssertEqual(model.focusedTask?.text, "next")
        XCTAssertEqual(model.remainingTasks.map(\.text), ["later"])
        XCTAssertEqual(model.completedTasks.map(\.text), ["done first", "done second"])
        XCTAssertFalse(model.isAllComplete)
    }

    func testAllCompleteHasNoFocusedOrRemainingTasks() {
        let tasks = [
            TaskItem(lineIndex: 1, text: "done first", isCompleted: true),
            TaskItem(lineIndex: 2, text: "done second", isCompleted: true),
        ]

        let model = TaskDisplayModel(tasks: tasks)

        XCTAssertNil(model.focusedTask)
        XCTAssertTrue(model.remainingTasks.isEmpty)
        XCTAssertEqual(model.completedTasks.map(\.text), ["done first", "done second"])
        XCTAssertTrue(model.isAllComplete)
    }

    func testEmptyTasksAreNotAllComplete() {
        let model = TaskDisplayModel(tasks: [])

        XCTAssertEqual(model.completedCount, 0)
        XCTAssertEqual(model.totalCount, 0)
        XCTAssertEqual(model.incompleteCount, 0)
        XCTAssertNil(model.focusedTask)
        XCTAssertTrue(model.remainingTasks.isEmpty)
        XCTAssertTrue(model.completedTasks.isEmpty)
        XCTAssertFalse(model.isAllComplete)
    }
}
```

- [ ] **Step 2: Run the tests to verify RED**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter TaskDisplayModelTests'
```

Expected: compile fails because `TaskDisplayModel` does not exist.

- [ ] **Step 3: Add the display model**

Create `Sources/NotchTodoCore/TaskDisplayModel.swift`:

```swift
public struct TaskDisplayModel: Equatable, Sendable {
    public let tasks: [TaskItem]

    public init(tasks: [TaskItem]) {
        self.tasks = tasks
    }

    public var completedCount: Int {
        tasks.lazy.filter(\.isCompleted).count
    }

    public var totalCount: Int {
        tasks.count
    }

    public var focusedTask: TaskItem? {
        tasks.first { !$0.isCompleted }
    }

    public var remainingTasks: [TaskItem] {
        Array(tasks.lazy.filter { !$0.isCompleted }.dropFirst())
    }

    public var completedTasks: [TaskItem] {
        tasks.filter(\.isCompleted)
    }

    public var incompleteCount: Int {
        tasks.lazy.filter { !$0.isCompleted }.count
    }

    public var isAllComplete: Bool {
        !tasks.isEmpty && incompleteCount == 0
    }
}
```

- [ ] **Step 4: Run the tests to verify GREEN**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter TaskDisplayModelTests'
```

Expected: `TaskDisplayModelTests` passes.

- [ ] **Step 5: Commit**

Run:

```bash
git add Sources/NotchTodoCore/TaskDisplayModel.swift Tests/NotchTodoCoreTests/TaskDisplayModelTests.swift
git commit -m "feat: add shared task display model"
```

Expected: commit succeeds with only these two files.

---

### Task 2: Shared Widget Bookmark and Snapshot Storage

**Files:**
- Create: `Sources/NotchTodoCore/WidgetSharedData.swift`
- Create: `Tests/NotchTodoCoreTests/WidgetSharedDataTests.swift`

- [ ] **Step 1: Write failing storage tests**

Create `Tests/NotchTodoCoreTests/WidgetSharedDataTests.swift`:

```swift
import Foundation
import XCTest
@testable import NotchTodoCore

final class WidgetSharedDataTests: XCTestCase {
    func testBookmarkStorePersistsBookmarkData() {
        let suiteName = "NotchTodoTests.WidgetSharedData.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let store = WidgetTaskFileBookmarkStore(defaults: defaults)
        let data = Data([1, 2, 3, 4])

        store.saveBookmark(data)

        XCTAssertEqual(store.loadBookmark(), data)
        store.clearBookmark()
        XCTAssertNil(store.loadBookmark())
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testSnapshotStoreRoundTripsTaskItems() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "NotchTodoWidgetSnapshot-\(UUID().uuidString)")
        let store = WidgetTaskSnapshotStore(directoryURL: directory)
        let tasks = [
            TaskItem(lineIndex: 10, text: "first", isCompleted: false),
            TaskItem(lineIndex: 11, text: "second", isCompleted: true),
        ]
        let generatedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = WidgetTaskSnapshot(generatedAt: generatedAt, tasks: tasks)

        try store.saveSnapshot(snapshot)

        let loaded = try XCTUnwrap(store.loadSnapshot())
        XCTAssertEqual(loaded.generatedAt, generatedAt)
        XCTAssertEqual(loaded.taskItems, tasks)
        store.clearSnapshot()
        XCTAssertNil(store.loadSnapshot())
        try? FileManager.default.removeItem(at: directory)
    }
}
```

- [ ] **Step 2: Run the tests to verify RED**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter WidgetSharedDataTests'
```

Expected: compile fails because `WidgetTaskFileBookmarkStore`, `WidgetTaskSnapshot`, and `WidgetTaskSnapshotStore` do not exist.

- [ ] **Step 3: Add shared widget storage**

Create `Sources/NotchTodoCore/WidgetSharedData.swift`:

```swift
import Foundation

public enum WidgetSharedData {
    public static let appGroupIdentifier = "group.com.firegnu.notchtodo"
    public static let widgetKind = "com.firegnu.notchtodo.tasks"
    public static let taskFileBookmarkKey = "widget.taskFileBookmark"
    public static let snapshotFileName = "task-snapshot.json"

    public static func appGroupDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    public static func appGroupContainerURL(
        fileManager: FileManager = .default
    ) -> URL? {
        fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
    }
}

public struct WidgetTaskFileBookmarkStore {
    private let defaults: UserDefaults?

    public init(defaults: UserDefaults?) {
        self.defaults = defaults
    }

    public func saveBookmark(_ data: Data) {
        defaults?.set(data, forKey: WidgetSharedData.taskFileBookmarkKey)
    }

    public func loadBookmark() -> Data? {
        defaults?.data(forKey: WidgetSharedData.taskFileBookmarkKey)
    }

    public func clearBookmark() {
        defaults?.removeObject(forKey: WidgetSharedData.taskFileBookmarkKey)
    }
}

public struct WidgetTaskSnapshot: Codable, Equatable, Sendable {
    public struct SnapshotTask: Codable, Equatable, Sendable {
        public let lineIndex: Int
        public let text: String
        public let isCompleted: Bool

        public init(lineIndex: Int, text: String, isCompleted: Bool) {
            self.lineIndex = lineIndex
            self.text = text
            self.isCompleted = isCompleted
        }
    }

    public let generatedAt: Date
    public let tasks: [SnapshotTask]

    public init(generatedAt: Date = Date(), tasks: [TaskItem]) {
        self.generatedAt = generatedAt
        self.tasks = tasks.map {
            SnapshotTask(
                lineIndex: $0.lineIndex,
                text: $0.text,
                isCompleted: $0.isCompleted
            )
        }
    }

    public var taskItems: [TaskItem] {
        tasks.map {
            TaskItem(
                lineIndex: $0.lineIndex,
                text: $0.text,
                isCompleted: $0.isCompleted
            )
        }
    }
}

public struct WidgetTaskSnapshotStore {
    private let directoryURL: URL?
    private let fileManager: FileManager

    public init(
        directoryURL: URL?,
        fileManager: FileManager = .default
    ) {
        self.directoryURL = directoryURL
        self.fileManager = fileManager
    }

    public func saveSnapshot(_ snapshot: WidgetTaskSnapshot) throws {
        guard let directoryURL else { return }
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder.widgetSnapshotEncoder.encode(snapshot)
        try data.write(to: snapshotURL(in: directoryURL), options: .atomic)
    }

    public func loadSnapshot() -> WidgetTaskSnapshot? {
        guard let directoryURL else { return nil }
        do {
            let data = try Data(contentsOf: snapshotURL(in: directoryURL))
            return try JSONDecoder.widgetSnapshotDecoder.decode(
                WidgetTaskSnapshot.self,
                from: data
            )
        } catch {
            return nil
        }
    }

    public func clearSnapshot() {
        guard let directoryURL else { return }
        try? fileManager.removeItem(at: snapshotURL(in: directoryURL))
    }

    private func snapshotURL(in directoryURL: URL) -> URL {
        directoryURL.appending(path: WidgetSharedData.snapshotFileName)
    }
}

private extension JSONEncoder {
    static var widgetSnapshotEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var widgetSnapshotDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
```

- [ ] **Step 4: Run the tests to verify GREEN**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter WidgetSharedDataTests'
```

Expected: `WidgetSharedDataTests` passes.

- [ ] **Step 5: Commit**

Run:

```bash
git add Sources/NotchTodoCore/WidgetSharedData.swift Tests/NotchTodoCoreTests/WidgetSharedDataTests.swift
git commit -m "feat: add widget shared storage"
```

Expected: commit succeeds with only these two files.

---

### Task 3: Mirror Main App State for the Widget

**Files:**
- Modify: `Sources/NotchTodoApp/TaskViewModel.swift`
- Modify: `Sources/NotchTodoApp/AppController.swift`
- Modify: `Tests/NotchTodoAppTests/TaskViewModelTests.swift`

- [ ] **Step 1: Add failing callback tests**

Append these tests to `Tests/NotchTodoAppTests/TaskViewModelTests.swift`:

```swift
    func testStateChangeCallbackRunsAfterStoreLoad() {
        let viewModel = TaskViewModel()
        let store = MockTaskFileStore()
        store.loadResult = .success([
            TaskItem(lineIndex: 1, text: "first", isCompleted: false),
        ])
        var callbackCount = 0
        viewModel.onStateChanged = {
            callbackCount += 1
        }

        viewModel.use(store: store)

        XCTAssertEqual(callbackCount, 1)
    }

    func testStateChangeCallbackRunsAfterToggle() {
        let viewModel = TaskViewModel()
        let original = TaskItem(lineIndex: 1, text: "first", isCompleted: false)
        let completed = TaskItem(lineIndex: 1, text: "first", isCompleted: true)
        let store = MockTaskFileStore()
        store.loadResult = .success([original])
        store.toggleResult = .success([completed])
        var callbackCount = 0
        viewModel.onStateChanged = {
            callbackCount += 1
        }
        viewModel.use(store: store)

        viewModel.toggle(original)

        XCTAssertEqual(callbackCount, 2)
    }
```

- [ ] **Step 2: Run the tests to verify RED**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter TaskViewModelTests'
```

Expected: compile fails because `TaskViewModel.onStateChanged` does not exist.

- [ ] **Step 3: Add a no-op default state callback**

Modify `Sources/NotchTodoApp/TaskViewModel.swift`:

```swift
@MainActor
final class TaskViewModel: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var error: TaskPanelError?

    var onStateChanged: (() -> Void)?

    private var store: (any TaskFileStoring)?
```

Then update `apply(_:)`:

```swift
    private func apply(_ tasks: [TaskItem]) {
        self.tasks = tasks
        error = nil
        onStateChanged?()
    }
```

Then update both `showError` overloads:

```swift
    func showError(_ message: String) {
        error = .generic(message: message)
        onStateChanged?()
    }

    func showError(_ panelError: TaskPanelError) {
        error = panelError
        onStateChanged?()
    }
```

Then update the private error classifier:

```swift
    private func showError(_ error: Swift.Error) {
        self.error = TaskPanelError.classified(from: error)
        onStateChanged?()
    }
```

- [ ] **Step 4: Run the tests to verify GREEN**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter TaskViewModelTests'
```

Expected: `TaskViewModelTests` passes.

- [ ] **Step 5: Wire AppController to mirror bookmark and snapshot**

Modify imports in `Sources/NotchTodoApp/AppController.swift`:

```swift
import AppKit
import NotchTodoCore
import UniformTypeIdentifiers
import WidgetKit
```

Add properties near the existing stored properties:

```swift
    private let widgetBookmarkStore = WidgetTaskFileBookmarkStore(
        defaults: WidgetSharedData.appGroupDefaults()
    )
    private let widgetSnapshotStore = WidgetTaskSnapshotStore(
        directoryURL: WidgetSharedData.appGroupContainerURL()
    )
```

At the top of `applicationDidFinishLaunching(_:)`, after `settings` is ready
and before `restoreTaskFile()`, set the callback:

```swift
        viewModel.onStateChanged = { [weak self] in
            self?.refreshWidgetState()
        }
```

In `selectTaskFile()`, after the existing `UserDefaults.standard.set` call,
save the widget bookmark:

```swift
            UserDefaults.standard.set(bookmark, forKey: DefaultsKey.taskFileBookmark)
            widgetBookmarkStore.saveBookmark(bookmark)
            useTaskFile(url)
```

In `restoreTaskFile()`, save or clear the widget bookmark:

```swift
    private func restoreTaskFile() {
        guard let bookmark = UserDefaults.standard.data(forKey: DefaultsKey.taskFileBookmark) else {
            widgetBookmarkStore.clearBookmark()
            return
        }

        do {
            widgetBookmarkStore.saveBookmark(bookmark)
            useTaskFile(try TaskFileStore.resolveBookmark(bookmark))
        } catch {
            widgetBookmarkStore.clearBookmark()
            viewModel.showError(.permissionLost(message: "任务文件权限已失效，请重新选择文件"))
        }
    }
```

Add this helper near the other private helpers:

```swift
    private func refreshWidgetState() {
        try? widgetSnapshotStore.saveSnapshot(
            WidgetTaskSnapshot(tasks: viewModel.tasks)
        )
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSharedData.widgetKind)
    }
```

- [ ] **Step 6: Run focused app tests**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter TaskViewModelTests'
```

Expected: `TaskViewModelTests` passes.

- [ ] **Step 7: Commit**

Run:

```bash
git add Sources/NotchTodoApp/TaskViewModel.swift Sources/NotchTodoApp/AppController.swift Tests/NotchTodoAppTests/TaskViewModelTests.swift
git commit -m "feat: mirror task state for widgets"
```

Expected: commit succeeds with only these three files.

---

### Task 4: WidgetKit Extension Source Target

**Files:**
- Create: `Sources/NotchTodoWidgetExtension/NotchTodoWidget.swift`
- Modify: `Package.swift`

- [ ] **Step 1: Add the SwiftPM widget executable target**

Modify `Package.swift` products:

```swift
    products: [
        .library(name: "NotchTodoCore", targets: ["NotchTodoCore"]),
        .executable(name: "NotchTodo", targets: ["NotchTodoApp"]),
        .executable(
            name: "NotchTodoWidgetExtension",
            targets: ["NotchTodoWidgetExtension"]
        ),
    ],
```

Add this target after `NotchTodoApp`:

```swift
        .executableTarget(
            name: "NotchTodoWidgetExtension",
            dependencies: ["NotchTodoCore"],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("WidgetKit"),
            ]
        ),
```

- [ ] **Step 2: Add the widget source file**

Create `Sources/NotchTodoWidgetExtension/NotchTodoWidget.swift`:

```swift
import SwiftUI
import WidgetKit
import NotchTodoCore

struct NotchTodoWidgetEntry: TimelineEntry {
    let date: Date
    let content: NotchTodoWidgetContent
}

enum NotchTodoWidgetContent: Equatable {
    case tasks(TaskDisplayModel, isSnapshot: Bool)
    case message(symbol: String, title: String, message: String)
}

struct NotchTodoWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> NotchTodoWidgetEntry {
        NotchTodoWidgetEntry(
            date: Date(),
            content: .tasks(
                TaskDisplayModel(tasks: [
                    TaskItem(lineIndex: 1, text: "完成项目周报", isCompleted: false),
                    TaskItem(lineIndex: 2, text: "准备会议材料", isCompleted: false),
                    TaskItem(lineIndex: 3, text: "回复客户邮件", isCompleted: true),
                ]),
                isSnapshot: false
            )
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (NotchTodoWidgetEntry) -> Void
    ) {
        completion(
            NotchTodoWidgetEntry(
                date: Date(),
                content: WidgetTaskLoader().load()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<NotchTodoWidgetEntry>) -> Void
    ) {
        let entry = NotchTodoWidgetEntry(
            date: Date(),
            content: WidgetTaskLoader().load()
        )
        let refreshDate = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: entry.date
        ) ?? entry.date.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

struct WidgetTaskLoader {
    private let bookmarkStore: WidgetTaskFileBookmarkStore
    private let snapshotStore: WidgetTaskSnapshotStore

    init(
        bookmarkStore: WidgetTaskFileBookmarkStore = WidgetTaskFileBookmarkStore(
            defaults: WidgetSharedData.appGroupDefaults()
        ),
        snapshotStore: WidgetTaskSnapshotStore = WidgetTaskSnapshotStore(
            directoryURL: WidgetSharedData.appGroupContainerURL()
        )
    ) {
        self.bookmarkStore = bookmarkStore
        self.snapshotStore = snapshotStore
    }

    func load() -> NotchTodoWidgetContent {
        if let bookmark = bookmarkStore.loadBookmark() {
            do {
                let url = try TaskFileStore.resolveBookmark(bookmark)
                let store = TaskFileStore(url: url)
                return .tasks(TaskDisplayModel(tasks: try store.load()), isSnapshot: false)
            } catch {
                return snapshotContent() ?? .message(
                    symbol: "lock.trianglebadge.exclamationmark",
                    title: "需要重新授权",
                    message: "打开 Notch Todo 重新选择 Markdown 文件"
                )
            }
        }

        return snapshotContent() ?? .message(
            symbol: "doc.badge.plus",
            title: "请选择任务文件",
            message: "打开 Notch Todo 选择 Markdown 文件"
        )
    }

    private func snapshotContent() -> NotchTodoWidgetContent? {
        guard let snapshot = snapshotStore.loadSnapshot() else { return nil }
        return .tasks(TaskDisplayModel(tasks: snapshot.taskItems), isSnapshot: true)
    }
}

struct NotchTodoWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: NotchTodoWidgetEntry

    var body: some View {
        ZStack {
            Color.black
            content
                .padding(family == .systemLarge ? 16 : 14)
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var content: some View {
        switch entry.content {
        case let .tasks(model, isSnapshot):
            taskCard(model, isSnapshot: isSnapshot)
        case let .message(symbol, title, message):
            stateView(symbol: symbol, title: title, message: message)
        }
    }

    private func taskCard(
        _ model: TaskDisplayModel,
        isSnapshot: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                Text("今天")
                    .font(.headline)
                Spacer()
                Text("\(model.completedCount)/\(model.totalCount)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.56))
            }

            if model.tasks.isEmpty {
                stateView(
                    symbol: "checklist",
                    title: "暂无任务",
                    message: "在 Markdown 的 Tasks 区域添加任务"
                )
            } else if let focusedTask = model.focusedTask {
                focusedTaskCard(focusedTask, remainingCount: model.incompleteCount)

                if family == .systemLarge {
                    taskSections(model)
                } else {
                    compactRemainingSummary(model)
                }
            } else {
                stateView(
                    symbol: "checkmark.circle",
                    title: "今天的任务已完成",
                    message: isSnapshot ? "显示最近一次快照" : "做得不错"
                )
            }
        }
    }

    private func focusedTaskCard(
        _ task: TaskItem,
        remainingCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("接下来")
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.66))
                Text(task.text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.94))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            Text("还剩 \(remainingCount) 项")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.leading, 26)
        }
        .padding(12)
        .background(
            Color(red: 0.065, green: 0.065, blue: 0.075),
            in: RoundedRectangle(cornerRadius: 13)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func taskSections(_ model: TaskDisplayModel) -> some View {
        if !model.remainingTasks.isEmpty {
            sectionHeader("稍后")
            ForEach(model.remainingTasks.prefix(3)) { task in
                taskRow(task)
            }
        }

        if !model.completedTasks.isEmpty {
            sectionHeader("已完成")
            ForEach(model.completedTasks.prefix(3)) { task in
                taskRow(task)
            }
        }
    }

    @ViewBuilder
    private func compactRemainingSummary(_ model: TaskDisplayModel) -> some View {
        if let nextTask = model.remainingTasks.first {
            HStack(spacing: 8) {
                Text("稍后")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.38))
                Text(nextTask.text)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(task.isCompleted ? 0.32 : 0.66))
            Text(task.text)
                .font(.system(size: 12))
                .strikethrough(task.isCompleted)
                .foregroundStyle(.white.opacity(task.isCompleted ? 0.34 : 0.88))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            .white.opacity(task.isCompleted ? 0.025 : 0.045),
            in: RoundedRectangle(cornerRadius: 9)
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.65)
            .foregroundStyle(.white.opacity(0.38))
    }

    private func stateView(
        symbol: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white.opacity(0.52))
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.44))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotchTodoTaskWidget: Widget {
    let kind = WidgetSharedData.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotchTodoWidgetProvider()) { entry in
            NotchTodoWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Notch Todo")
        .description("显示今天的 Markdown 任务")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct NotchTodoWidgetBundle: WidgetBundle {
    var body: some Widget {
        NotchTodoTaskWidget()
    }
}
```

- [ ] **Step 3: Build only the widget product**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift build -c release --product NotchTodoWidgetExtension'
```

Expected: `Build complete!` and `.build/release/NotchTodoWidgetExtension` exists.

- [ ] **Step 4: Commit**

Run:

```bash
git add Package.swift Sources/NotchTodoWidgetExtension/NotchTodoWidget.swift
git commit -m "feat: add widget extension target"
```

Expected: commit succeeds with the package and widget source files.

---

### Task 5: Widget Bundle Metadata, Entitlements, and Packaging

**Files:**
- Create: `Resources/NotchTodoWidgetExtension-Info.plist`
- Create: `Resources/NotchTodoWidgetExtension.entitlements`
- Modify: `Resources/NotchTodo.entitlements`
- Modify: `Tests/NotchTodoAppTests/InfoPlistTests.swift`
- Modify: `scripts/build-app.sh`

- [ ] **Step 1: Add failing plist and entitlement tests**

Append these tests to `Tests/NotchTodoAppTests/InfoPlistTests.swift`:

```swift
    func testAppGroupEntitlementExistsWithoutEnablingMainAppSandbox() throws {
        let entitlements = try loadPlist("NotchTodo.entitlements")
        let groups = try XCTUnwrap(
            entitlements["com.apple.security.application-groups"] as? [String]
        )

        XCTAssertTrue(groups.contains("group.com.firegnu.notchtodo"))
        XCTAssertNil(
            entitlements["com.apple.security.app-sandbox"],
            "Do not enable sandbox without rechecking Markdown file monitoring."
        )
    }

    func testWidgetExtensionInfoPlistDeclaresWidgetKitExtensionPoint() throws {
        let plist = try loadPlist("NotchTodoWidgetExtension-Info.plist")
        let extensionInfo = try XCTUnwrap(plist["NSExtension"] as? [String: Any])
        let point = try XCTUnwrap(
            extensionInfo["NSExtensionPointIdentifier"] as? String
        )

        XCTAssertEqual(point, "com.apple.widgetkit-extension")
        XCTAssertEqual(plist["CFBundlePackageType"] as? String, "XPC!")
    }

    func testWidgetExtensionEntitlementsUseSandboxAndAppGroup() throws {
        let entitlements = try loadPlist("NotchTodoWidgetExtension.entitlements")
        let sandbox = try XCTUnwrap(
            entitlements["com.apple.security.app-sandbox"] as? Bool
        )
        let bookmarkAccess = try XCTUnwrap(
            entitlements["com.apple.security.files.bookmarks.app-scope"] as? Bool
        )
        let groups = try XCTUnwrap(
            entitlements["com.apple.security.application-groups"] as? [String]
        )

        XCTAssertTrue(sandbox)
        XCTAssertTrue(bookmarkAccess)
        XCTAssertTrue(groups.contains("group.com.firegnu.notchtodo"))
    }
```

- [ ] **Step 2: Run the tests to verify RED**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter InfoPlistTests'
```

Expected: tests fail because the widget plist, widget entitlements, and app group entitlement are missing.

- [ ] **Step 3: Add the widget extension plist**

Create `Resources/NotchTodoWidgetExtension-Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleDisplayName</key>
    <string>Notch Todo Widget</string>
    <key>CFBundleExecutable</key>
    <string>NotchTodoWidgetExtension</string>
    <key>CFBundleIdentifier</key>
    <string>com.firegnu.notchtodo.widget</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Notch Todo Widget</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
```

- [ ] **Step 4: Add widget and host app entitlements**

Create `Resources/NotchTodoWidgetExtension.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.firegnu.notchtodo</string>
    </array>
</dict>
</plist>
```

Modify `Resources/NotchTodo.entitlements` to include the App Group while keeping
the existing Calendar entitlement and leaving sandbox disabled:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.personal-information.calendars</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.firegnu.notchtodo</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 5: Run plist tests to verify GREEN**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test --filter InfoPlistTests'
```

Expected: `InfoPlistTests` passes.

- [ ] **Step 6: Update the app build script to embed the widget extension**

Modify `scripts/build-app.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/Notch Todo.app"
EXECUTABLE="$ROOT/.build/release/NotchTodo"
WIDGET_EXECUTABLE="$ROOT/.build/release/NotchTodoWidgetExtension"
WIDGET_APPEX="$APP/Contents/PlugIns/NotchTodoWidgetExtension.appex"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="$ROOT/.build/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT/.build/swiftpm-module-cache"

cd "$ROOT"
swift build -c release --product NotchTodo
swift build -c release --product NotchTodoWidgetExtension

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mkdir -p "$WIDGET_APPEX/Contents/MacOS" "$WIDGET_APPEX/Contents/Resources"

cp "$EXECUTABLE" "$APP/Contents/MacOS/NotchTodo"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Resources/labubu-pixel.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel@2x.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel@3x.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel-blink.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel-blink@2x.png" "$APP/Contents/Resources/"
cp "$ROOT/Resources/labubu-pixel-blink@3x.png" "$APP/Contents/Resources/"

cp "$WIDGET_EXECUTABLE" "$WIDGET_APPEX/Contents/MacOS/NotchTodoWidgetExtension"
cp "$ROOT/Resources/NotchTodoWidgetExtension-Info.plist" "$WIDGET_APPEX/Contents/Info.plist"

codesign --force --options runtime \
  --entitlements "$ROOT/Resources/NotchTodoWidgetExtension.entitlements" \
  --sign - "$WIDGET_APPEX"

codesign --force --options runtime \
  --entitlements "$ROOT/Resources/NotchTodo.entitlements" \
  --sign - "$APP"

printf 'Built %s\n' "$APP"
```

- [ ] **Step 7: Run the full build**

Run:

```bash
./scripts/build-app.sh
```

Expected: `Built /Users/firegnu/Developer/personal_projs/notch-todo/build/Notch Todo.app`.

- [ ] **Step 8: Verify the app bundle contains the widget extension**

Run:

```bash
/usr/bin/find "build/Notch Todo.app/Contents/PlugIns/NotchTodoWidgetExtension.appex" -maxdepth 3 -type f | sort
```

Expected output includes:

```text
build/Notch Todo.app/Contents/PlugIns/NotchTodoWidgetExtension.appex/Contents/Info.plist
build/Notch Todo.app/Contents/PlugIns/NotchTodoWidgetExtension.appex/Contents/MacOS/NotchTodoWidgetExtension
```

- [ ] **Step 9: Commit**

Run:

```bash
git add Resources/NotchTodo.entitlements Resources/NotchTodoWidgetExtension-Info.plist Resources/NotchTodoWidgetExtension.entitlements Tests/NotchTodoAppTests/InfoPlistTests.swift scripts/build-app.sh
git commit -m "build: embed desktop widget extension"
```

Expected: commit succeeds with only packaging, resources, and tests.

---

### Task 6: Full Regression and Widget Discovery Check

**Files:**
- No source files should change in this task unless a verification failure identifies a specific defect.

- [ ] **Step 1: Run the full test suite**

Run:

```bash
/bin/zsh -lc 'DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-module-cache" SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/swiftpm-module-cache" swift test'
```

Expected: all tests pass.

- [ ] **Step 2: Build the app bundle**

Run:

```bash
./scripts/build-app.sh
```

Expected: app bundle builds and signs successfully.

- [ ] **Step 3: Install locally**

Run:

```bash
./scripts/install-app.sh
```

Expected: `/Applications/Notch Todo.app` is replaced and launched.

- [ ] **Step 4: Check WidgetKit extension registration**

Run:

```bash
pluginkit -m -v -p com.apple.widgetkit-extension | rg 'com.firegnu.notchtodo.widget|Notch Todo'
```

Expected: output includes `com.firegnu.notchtodo.widget`.

- [ ] **Step 5: Manual behavior check**

Verify manually:

```text
1. Existing notch panel appears on the built-in notched display.
2. Hover expands the existing panel.
3. Settings page opens and returns to tasks.
4. A checkbox toggle updates the Markdown file.
5. The macOS widget gallery shows Notch Todo.
6. Adding the widget to the desktop shows the task card.
7. Quitting Notch Todo leaves the desktop widget visible.
```

- [ ] **Step 6: Record verification result in the final response**

Report:

```text
Tests: swift test
Build: ./scripts/build-app.sh
Widget registration: pluginkit check result
Manual checks completed or not completed
```

If the direct-read path cannot access the Markdown file from the widget, report
that the widget is using the snapshot fallback and include the exact failure
seen during manual verification.
