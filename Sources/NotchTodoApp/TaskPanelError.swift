import Foundation
import NotchTodoCore

enum TaskPanelError: Equatable {
    enum Kind: Equatable {
        case fileMissing
        case noFileSelected
        case permissionLost
        case markdownFormat
        case writeConflict
        case generic
    }

    case fileMissing(message: String)
    case noFileSelected(message: String)
    case permissionLost(message: String)
    case markdownFormat(message: String)
    case writeConflict(message: String)
    case generic(message: String)

    var kind: Kind {
        switch self {
        case .fileMissing:
            .fileMissing
        case .noFileSelected:
            .noFileSelected
        case .permissionLost:
            .permissionLost
        case .markdownFormat:
            .markdownFormat
        case .writeConflict:
            .writeConflict
        case .generic:
            .generic
        }
    }

    var message: String {
        switch self {
        case let .fileMissing(message),
             let .noFileSelected(message),
             let .permissionLost(message),
             let .markdownFormat(message),
             let .writeConflict(message),
             let .generic(message):
            message
        }
    }

    var stateContent: TaskPanelStateContent {
        switch self {
        case .fileMissing:
            TaskPanelStateContent.fileMissing
        case .noFileSelected:
            TaskPanelStateContent.noFileSelected
        case .permissionLost:
            TaskPanelStateContent.permissionLost
        case .markdownFormat:
            TaskPanelStateContent.markdownFormat
        case .writeConflict:
            TaskPanelStateContent.writeConflict
        case .generic:
            TaskPanelStateContent.error
        }
    }

    var recoveryActionTitle: String? {
        switch self {
        case .fileMissing, .permissionLost, .markdownFormat:
            "重新选择文件"
        case .noFileSelected:
            "选择文件"
        case .writeConflict:
            "重新加载"
        case .generic:
            nil
        }
    }

    static func classified(from error: Swift.Error) -> TaskPanelError {
        if let parserError = error as? MarkdownTaskParser.Error {
            switch parserError {
            case .missingTasksSection, .duplicateTasksSection:
                return .markdownFormat(message: parserError.localizedDescription)
            case .taskConflict:
                return .writeConflict(message: parserError.localizedDescription)
            }
        }

        if let storeError = error as? TaskFileStore.Error,
           storeError == .staleBookmark {
            return .permissionLost(message: "任务文件权限已失效，请重新选择文件")
        }

        if isMissingFile(error) {
            return .fileMissing(message: "任务文件不存在，请重新选择文件")
        }

        return .generic(message: error.localizedDescription)
    }

    private static func isMissingFile(_ error: Swift.Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSCocoaErrorDomain else {
            return false
        }
        return nsError.code == CocoaError.Code.fileNoSuchFile.rawValue
            || nsError.code == CocoaError.Code.fileReadNoSuchFile.rawValue
    }
}
