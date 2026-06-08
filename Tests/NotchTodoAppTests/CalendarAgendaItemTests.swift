import Foundation
import XCTest
@testable import NotchTodoApp

final class CalendarAgendaItemTests: XCTestCase {
    func testTimedEventFormatsTimeRange() {
        let calendar = Calendar(identifier: .gregorian)
        let start = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 6,
            day: 8,
            hour: 14,
            minute: 5
        ).date!
        let end = DateComponents(
            calendar: calendar,
            year: 2026,
            month: 6,
            day: 8,
            hour: 15,
            minute: 30
        ).date!

        let item = CalendarAgendaItem(
            id: "event-1",
            title: "产品评审",
            startDate: start,
            endDate: end,
            isAllDay: false
        )

        XCTAssertEqual(item.timeText, "14:05-15:30")
    }

    func testAllDayEventFormatsAsAllDay() {
        let item = CalendarAgendaItem(
            id: "event-2",
            title: "发布日",
            startDate: Date(),
            endDate: Date(),
            isAllDay: true
        )

        XCTAssertEqual(item.timeText, "全天")
    }
}
