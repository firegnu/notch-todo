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

    func testAppAndWidgetDeclareDefaultAppGroupIdentifier() throws {
        let appPlist = try loadPlist("Info.plist")
        let widgetPlist = try loadPlist("NotchTodoWidgetExtension-Info.plist")

        XCTAssertEqual(
            appPlist["NotchTodoAppGroupIdentifier"] as? String,
            "group.com.firegnu.notchtodo"
        )
        XCTAssertEqual(
            widgetPlist["NotchTodoAppGroupIdentifier"] as? String,
            "group.com.firegnu.notchtodo"
        )
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
