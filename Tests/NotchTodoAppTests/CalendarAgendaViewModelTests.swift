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
            CalendarAgendaSelection(id: "work", title: "工作", sourceTitle: "iCloud"),
        ]
        provider.eventsByCalendarID["work"] = [
            CalendarAgendaItem(
                id: "event",
                title: "站会",
                startDate: Date(timeIntervalSince1970: 100),
                endDate: Date(timeIntervalSince1970: 200),
                isAllDay: false
            ),
        ]
        let viewModel = CalendarAgendaViewModel(provider: provider, defaults: defaults)

        viewModel.selectCalendar(
            provider.availableCalendars[0],
            now: Date(timeIntervalSince1970: 50)
        )

        XCTAssertTrue(viewModel.isEnabled)
        XCTAssertEqual(viewModel.selectedCalendarTitle, "iCloud / 工作")
        XCTAssertEqual(viewModel.events.map(\.title), ["站会"])
        XCTAssertEqual(
            defaults.string(forKey: CalendarAgendaDefaultsKey.selectedCalendarID),
            "work"
        )
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

    func testRequestDeniedKeepsCalendarDisabled() async {
        let defaults = UserDefaults(suiteName: "CalendarAgendaViewModelTests.denied")!
        defaults.removePersistentDomain(forName: "CalendarAgendaViewModelTests.denied")
        let provider = MockCalendarAgendaProvider()
        provider.fullAccess = false
        let viewModel = CalendarAgendaViewModel(provider: provider, defaults: defaults)

        let granted = await viewModel.requestAccessAndEnable()

        XCTAssertFalse(granted)
        XCTAssertFalse(viewModel.isEnabled)
        XCTAssertEqual(viewModel.errorMessage, "未获得 Calendar 访问权限")
    }

    func testRequestGrantedWithoutFullAccessKeepsCalendarDisabled() async {
        let defaults = UserDefaults(suiteName: "CalendarAgendaViewModelTests.grantedWithoutAccess")!
        defaults.removePersistentDomain(forName: "CalendarAgendaViewModelTests.grantedWithoutAccess")
        let provider = MockCalendarAgendaProvider()
        provider.requestFullAccessResult = true
        provider.fullAccess = false
        provider.statusDescription = "denied"
        let viewModel = CalendarAgendaViewModel(provider: provider, defaults: defaults)

        let granted = await viewModel.requestAccessAndEnable()

        XCTAssertFalse(granted)
        XCTAssertFalse(viewModel.isEnabled)
        XCTAssertEqual(
            viewModel.errorMessage,
            "未获得 Calendar 访问权限（当前状态：denied）"
        )
        XCTAssertFalse(defaults.bool(forKey: CalendarAgendaDefaultsKey.isEnabled))
    }

    func testRefreshPolicyKeepsRecommendedIntervals() {
        XCTAssertEqual(CalendarAgendaRefreshPolicy.panelRefreshInterval, 60)
        XCTAssertEqual(CalendarAgendaRefreshPolicy.backgroundRefreshInterval, 300)
    }

    func testReloadIfStaleSkipsRecentReload() {
        let defaults = UserDefaults(suiteName: "CalendarAgendaViewModelTests.recent")!
        defaults.removePersistentDomain(forName: "CalendarAgendaViewModelTests.recent")
        let provider = MockCalendarAgendaProvider()
        provider.availableCalendars = [
            CalendarAgendaSelection(id: "work", title: "工作", sourceTitle: "iCloud"),
        ]
        provider.eventsByCalendarID["work"] = []
        let viewModel = CalendarAgendaViewModel(provider: provider, defaults: defaults)
        viewModel.selectCalendar(
            provider.availableCalendars[0],
            now: Date(timeIntervalSince1970: 100)
        )

        viewModel.reloadIfStale(
            now: Date(timeIntervalSince1970: 150),
            staleAfter: CalendarAgendaRefreshPolicy.panelRefreshInterval
        )

        XCTAssertEqual(provider.eventRequestCount, 1)
    }

    func testReloadIfStaleReloadsAfterInterval() {
        let defaults = UserDefaults(suiteName: "CalendarAgendaViewModelTests.stale")!
        defaults.removePersistentDomain(forName: "CalendarAgendaViewModelTests.stale")
        let provider = MockCalendarAgendaProvider()
        provider.availableCalendars = [
            CalendarAgendaSelection(id: "work", title: "工作", sourceTitle: "iCloud"),
        ]
        provider.eventsByCalendarID["work"] = []
        let viewModel = CalendarAgendaViewModel(provider: provider, defaults: defaults)
        viewModel.selectCalendar(
            provider.availableCalendars[0],
            now: Date(timeIntervalSince1970: 100)
        )

        viewModel.reloadIfStale(
            now: Date(timeIntervalSince1970: 161),
            staleAfter: CalendarAgendaRefreshPolicy.panelRefreshInterval
        )

        XCTAssertEqual(provider.eventRequestCount, 2)
    }
}

private final class MockCalendarAgendaProvider: CalendarAgendaProviding {
    var fullAccess = true
    var requestFullAccessResult: Bool?
    var statusDescription = "fullAccess"
    var availableCalendars: [CalendarAgendaSelection] = []
    var eventsByCalendarID: [String: [CalendarAgendaItem]] = [:]
    var eventRequestCount = 0

    func hasFullAccess() -> Bool {
        fullAccess
    }

    func accessStatusDescription() -> String {
        statusDescription
    }

    func requestFullAccess() async throws -> Bool {
        requestFullAccessResult ?? fullAccess
    }

    func calendars() -> [CalendarAgendaSelection] {
        availableCalendars
    }

    func events(
        for calendarID: String,
        on date: Date,
        now: Date
    ) throws -> [CalendarAgendaItem] {
        eventRequestCount += 1
        guard let events = eventsByCalendarID[calendarID] else {
            throw CalendarAgendaError.calendarMissing
        }
        return events
    }
}
