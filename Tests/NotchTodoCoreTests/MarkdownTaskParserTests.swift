import XCTest
@testable import NotchTodoCore

final class MarkdownTaskParserTests: XCTestCase {
    private let parser = MarkdownTaskParser()

    func testParsesOnlyUnindentedTasksInsideTasksSection() throws {
        let markdown = """
        # Tomorrow

        - [ ] ignored

        ## Tasks

        - [ ] First task
        - [x] Finished task
        - [X] Also finished
          - [ ] nested task

        ## Notes

        - [ ] ignored too
        """

        let tasks = try parser.parse(markdown)

        XCTAssertEqual(
            tasks,
            [
                TaskItem(lineIndex: 6, text: "First task", isCompleted: false),
                TaskItem(lineIndex: 7, text: "Finished task", isCompleted: true),
                TaskItem(lineIndex: 8, text: "Also finished", isCompleted: true),
            ]
        )
    }

    func testEmptyTasksSectionIsValid() throws {
        let tasks = try parser.parse("# Tomorrow\n\n## Tasks\n\n## Notes\nNothing")

        XCTAssertEqual(tasks, [])
    }

    func testMissingTasksSectionFails() {
        XCTAssertThrowsError(try parser.parse("# Tomorrow\n\n- [ ] Task")) { error in
            XCTAssertEqual(error as? MarkdownTaskParser.Error, .missingTasksSection)
        }
    }

    func testFormatErrorsHaveUserReadableDescriptions() {
        XCTAssertEqual(
            MarkdownTaskParser.Error.missingTasksSection.errorDescription,
            "未找到唯一的 ## Tasks 区块"
        )
    }

    func testDuplicateTasksSectionFails() {
        let markdown = "## Tasks\n- [ ] One\n\n## Tasks\n- [ ] Two"

        XCTAssertThrowsError(try parser.parse(markdown)) { error in
            XCTAssertEqual(error as? MarkdownTaskParser.Error, .duplicateTasksSection)
        }
    }

    func testToggleChangesOnlyCheckboxMarker() throws {
        let markdown = "# Tomorrow\n\n## Tasks\n\n- [ ] Keep **formatting**\n\nFooter\n"
        let task = try XCTUnwrap(parser.parse(markdown).first)

        let updated = try parser.toggling(task, in: markdown)

        XCTAssertEqual(updated, "# Tomorrow\n\n## Tasks\n\n- [x] Keep **formatting**\n\nFooter\n")
    }

    func testToggleRejectsChangedSourceLine() throws {
        let original = "## Tasks\n- [ ] Original"
        let changed = "## Tasks\n- [ ] Changed externally"
        let task = try XCTUnwrap(parser.parse(original).first)

        XCTAssertThrowsError(try parser.toggling(task, in: changed)) { error in
            XCTAssertEqual(error as? MarkdownTaskParser.Error, .taskConflict)
        }
    }

    func testToggleCanRestoreCompletedTask() throws {
        let markdown = "## Tasks\n- [X] Done"
        let task = try XCTUnwrap(parser.parse(markdown).first)

        XCTAssertEqual(try parser.toggling(task, in: markdown), "## Tasks\n- [ ] Done")
    }
}
