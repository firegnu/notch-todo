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
