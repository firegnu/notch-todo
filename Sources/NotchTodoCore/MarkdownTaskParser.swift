import Foundation

public struct MarkdownTaskParser: Sendable {
    public enum Error: Swift.Error, LocalizedError, Equatable {
        case missingTasksSection
        case duplicateTasksSection
        case taskConflict

        public var errorDescription: String? {
            switch self {
            case .missingTasksSection:
                "未找到唯一的 ## Tasks 区块"
            case .duplicateTasksSection:
                "文件中存在多个 ## Tasks 区块"
            case .taskConflict:
                "任务已被外部修改，请重试"
            }
        }
    }

    public init() {}

    public func parse(_ markdown: String) throws -> [TaskItem] {
        let lines = markdown.components(separatedBy: "\n")
        let sectionLines = lines.indices.filter {
            lines[$0].trimmingCharacters(in: .whitespaces) == "## Tasks"
        }

        guard let sectionStart = sectionLines.first else {
            throw Error.missingTasksSection
        }
        guard sectionLines.count == 1 else {
            throw Error.duplicateTasksSection
        }

        let sectionEnd = lines.indices.dropFirst(sectionStart + 1).first {
            isLevelTwoHeading(lines[$0])
        } ?? lines.endIndex

        return lines.indices[(sectionStart + 1)..<sectionEnd].compactMap { index in
            parseTaskLine(lines[index], at: index)
        }
    }

    public func toggling(_ task: TaskItem, in markdown: String) throws -> String {
        var lines = markdown.components(separatedBy: "\n")
        guard lines.indices.contains(task.lineIndex),
              let currentTask = parseTaskLine(lines[task.lineIndex], at: task.lineIndex),
              currentTask == task
        else {
            throw Error.taskConflict
        }

        let replacement = task.isCompleted ? " " : "x"
        lines[task.lineIndex].replaceSubrange(
            lines[task.lineIndex].index(lines[task.lineIndex].startIndex, offsetBy: 3)...lines[task.lineIndex].index(lines[task.lineIndex].startIndex, offsetBy: 3),
            with: replacement
        )
        return lines.joined(separator: "\n")
    }

    private func isLevelTwoHeading(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("## ") && !trimmed.hasPrefix("### ")
    }

    private func parseTaskLine(_ line: String, at index: Int) -> TaskItem? {
        let prefixes = ["- [ ] ", "- [x] ", "- [X] "]
        guard let prefix = prefixes.first(where: line.hasPrefix) else {
            return nil
        }

        return TaskItem(
            lineIndex: index,
            text: String(line.dropFirst(prefix.count)),
            isCompleted: prefix != "- [ ] "
        )
    }
}
