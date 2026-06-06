public struct TaskItem: Equatable, Sendable, Identifiable {
    public let lineIndex: Int
    public let text: String
    public let isCompleted: Bool

    public var id: String {
        "\(lineIndex):\(text)"
    }

    public init(lineIndex: Int, text: String, isCompleted: Bool) {
        self.lineIndex = lineIndex
        self.text = text
        self.isCompleted = isCompleted
    }
}
