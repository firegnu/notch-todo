import Darwin
import Dispatch
import Foundation

public protocol TaskFileStoring: AnyObject, Sendable {
    var url: URL { get }

    func load() throws -> [TaskItem]
    func toggle(_ task: TaskItem) throws -> [TaskItem]
    func startMonitoring(
        onChange: @escaping @Sendable (Result<[TaskItem], Swift.Error>) -> Void
    ) throws
    func stopMonitoring()
}

public final class TaskFileStore: TaskFileStoring, @unchecked Sendable {
    public enum Error: Swift.Error, Equatable {
        case staleBookmark
        case cannotMonitorDirectory
    }

    public let url: URL

    private let parser: MarkdownTaskParser
    private let monitorQueue = DispatchQueue(label: "NotchTodo.TaskFileStore.monitor")
    private let stateLock = NSLock()
    private var monitor: DispatchSourceFileSystemObject?
    private let hasSecurityScope: Bool

    public init(url: URL, parser: MarkdownTaskParser = MarkdownTaskParser()) {
        self.url = url
        self.parser = parser
        hasSecurityScope = url.startAccessingSecurityScopedResource()
    }

    deinit {
        stopMonitoring()
        if hasSecurityScope {
            url.stopAccessingSecurityScopedResource()
        }
    }

    public func load() throws -> [TaskItem] {
        try parser.parse(readMarkdown())
    }

    public func toggle(_ task: TaskItem) throws -> [TaskItem] {
        let latestMarkdown = try readMarkdown()
        let updatedMarkdown = try parser.toggling(task, in: latestMarkdown)
        try Data(updatedMarkdown.utf8).write(to: url, options: .atomic)
        return try parser.parse(updatedMarkdown)
    }

    public func startMonitoring(
        onChange: @escaping @Sendable (Result<[TaskItem], Swift.Error>) -> Void
    ) throws {
        stopMonitoring()

        let directory = url.deletingLastPathComponent()
        let descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else {
            throw Error.cannotMonitorDirectory
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete],
            queue: monitorQueue
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            onChange(Result { try self.load() })
        }
        source.setCancelHandler {
            close(descriptor)
        }

        stateLock.withLock {
            monitor = source
        }
        source.resume()
    }

    public func stopMonitoring() {
        let source = stateLock.withLock {
            let current = monitor
            monitor = nil
            return current
        }
        source?.cancel()
    }

    public static func makeBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    public static func resolveBookmark(_ data: Data) throws -> URL {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        guard !isStale else {
            throw Error.staleBookmark
        }
        return url
    }

    private func readMarkdown() throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }
}
