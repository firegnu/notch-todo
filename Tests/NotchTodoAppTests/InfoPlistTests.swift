import Foundation
import XCTest

final class InfoPlistTests: XCTestCase {
    func testCalendarFullAccessUsageDescriptionExists() throws {
        let plist = try loadPlist("Info.plist")
        let value = try XCTUnwrap(
            plist["NSCalendarsFullAccessUsageDescription"] as? String
        )

        XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testCalendarEntitlementExists() throws {
        let entitlements = try loadPlist("NotchTodo.entitlements")
        let hasCalendarAccess = try XCTUnwrap(
            entitlements["com.apple.security.personal-information.calendars"] as? Bool
        )

        XCTAssertTrue(hasCalendarAccess)
        XCTAssertNil(
            entitlements["com.apple.security.app-sandbox"],
            "Do not enable sandbox without rechecking Markdown file monitoring."
        )
    }

    private func loadPlist(_ name: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Resources/\(name)")
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
    }
}
