import Foundation

struct CalendarAgendaItem: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool

    var timeText: String {
        if isAllDay {
            return "全天"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startDate))-\(formatter.string(from: endDate))"
    }
}

struct CalendarAgendaSelection: Equatable, Identifiable {
    static let allCalendarsID = "calendarAgenda.allCalendars"
    static let allCalendars = CalendarAgendaSelection(
        id: allCalendarsID,
        title: "所有日历",
        sourceTitle: ""
    )

    let id: String
    let title: String
    let sourceTitle: String

    var isAllCalendars: Bool {
        id == Self.allCalendarsID
    }

    var displayTitle: String {
        sourceTitle.isEmpty ? title : "\(sourceTitle) / \(title)"
    }
}
