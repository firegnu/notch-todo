import EventKit
import Foundation

enum CalendarAgendaError: Error, Equatable {
    case accessDenied
    case calendarMissing
}

@MainActor
protocol CalendarAgendaProviding: AnyObject {
    func hasFullAccess() -> Bool
    func accessStatusDescription() -> String
    func requestFullAccess() async throws -> Bool
    func calendars() -> [CalendarAgendaSelection]
    func events(
        for calendarID: String,
        on date: Date,
        now: Date
    ) throws -> [CalendarAgendaItem]
}

enum CalendarAgendaCalendarMapper {
    struct Input {
        let id: String
        let title: String
        let sourceTitle: String
        let isSubscribed: Bool
    }

    static func selections(from inputs: [Input]) -> [CalendarAgendaSelection] {
        guard !inputs.isEmpty else {
            return [.allCalendars]
        }

        return inputs
            .sorted { left, right in
                left.title.localizedCompare(right.title) == .orderedAscending
            }
            .map { calendar in
                CalendarAgendaSelection(
                    id: calendar.id,
                    title: calendar.title,
                    sourceTitle: calendar.sourceTitle
                )
            }
    }
}

final class EventKitCalendarAgendaProvider: CalendarAgendaProviding {
    private let store = EKEventStore()

    func hasFullAccess() -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            return true
        case .authorized:
            return true
        default:
            return false
        }
    }

    func accessStatusDescription() -> String {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        case .writeOnly:
            return "writeOnly"
        case .fullAccess:
            return "fullAccess"
        @unknown default:
            return "unknown"
        }
    }

    func requestFullAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            store.requestFullAccessToEvents { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func calendars() -> [CalendarAgendaSelection] {
        CalendarAgendaCalendarMapper.selections(
            from: store.calendars(for: .event).map { calendar in
                CalendarAgendaCalendarMapper.Input(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    sourceTitle: calendar.source?.title ?? "",
                    isSubscribed: calendar.isSubscribed
                )
            }
        )
    }

    func events(
        for calendarID: String,
        on date: Date,
        now: Date
    ) throws -> [CalendarAgendaItem] {
        let calendars: [EKCalendar]?
        if calendarID == CalendarAgendaSelection.allCalendarsID {
            calendars = nil
        } else {
            guard let calendar = store.calendar(withIdentifier: calendarID) else {
                throw CalendarAgendaError.calendarMissing
            }
            calendars = [calendar]
        }

        let currentCalendar = Calendar.current
        let start = currentCalendar.startOfDay(for: date)
        let end = currentCalendar.date(byAdding: .day, value: 1, to: start) ?? date
        let predicate = store.predicateForEvents(
            withStart: start,
            end: end,
            calendars: calendars
        )

        return store.events(matching: predicate)
            .filter { $0.isAllDay || $0.endDate >= now }
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                CalendarAgendaItem(
                    id: event.eventIdentifier,
                    title: event.title,
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay
                )
            }
    }
}
