import XCTest
@testable import NotchTodoApp

final class CalendarAgendaProviderTests: XCTestCase {
    func testEmptyCalendarListFallsBackToAllCalendars() {
        XCTAssertEqual(
            CalendarAgendaCalendarMapper.selections(from: []),
            [.allCalendars]
        )
    }

    func testSubscribedCalendarsRemainAvailableForReadOnlyDisplay() {
        let selections = CalendarAgendaCalendarMapper.selections(
            from: [
                CalendarAgendaCalendarMapper.Input(
                    id: "subscribed",
                    title: "订阅日历",
                    sourceTitle: "iCloud",
                    isSubscribed: true
                )
            ]
        )

        XCTAssertEqual(
            selections,
            [
                CalendarAgendaSelection(
                    id: "subscribed",
                    title: "订阅日历",
                    sourceTitle: "iCloud"
                )
            ]
        )
    }
}
