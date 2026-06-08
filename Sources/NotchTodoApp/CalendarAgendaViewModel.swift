import Combine
import Foundation

enum CalendarAgendaDefaultsKey {
    static let isEnabled = "calendarAgenda.isEnabled"
    static let selectedCalendarID = "calendarAgenda.selectedCalendarID"
    static let selectedCalendarTitle = "calendarAgenda.selectedCalendarTitle"
}

enum CalendarAgendaRefreshPolicy {
    static let panelRefreshInterval: TimeInterval = 60
    static let backgroundRefreshInterval: TimeInterval = 300
    static let backgroundRefreshDuration = Duration.seconds(300)
}

@MainActor
final class CalendarAgendaViewModel: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var selectedCalendarID: String?
    @Published private(set) var selectedCalendarTitle: String?
    @Published private(set) var events: [CalendarAgendaItem] = []
    @Published private(set) var errorMessage: String?
    private(set) var lastReloadAt: Date?

    private let provider: CalendarAgendaProviding
    private let defaults: UserDefaults

    init(
        provider: CalendarAgendaProviding,
        defaults: UserDefaults = .standard
    ) {
        self.provider = provider
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: CalendarAgendaDefaultsKey.isEnabled)
        selectedCalendarID = defaults.string(
            forKey: CalendarAgendaDefaultsKey.selectedCalendarID
        )
        selectedCalendarTitle = defaults.string(
            forKey: CalendarAgendaDefaultsKey.selectedCalendarTitle
        )
    }

    var isConfigured: Bool {
        isEnabled && selectedCalendarID != nil
    }

    var availableCalendars: [CalendarAgendaSelection] {
        provider.calendars()
    }

    @discardableResult
    func requestAccessAndEnable() async -> Bool {
        do {
            let granted = try await provider.requestFullAccess()
            guard granted else {
                disableWithError("未获得 Calendar 访问权限")
                return false
            }
            guard provider.hasFullAccess() else {
                disableWithError(
                    "未获得 Calendar 访问权限（当前状态：\(provider.accessStatusDescription())）"
                )
                return false
            }

            isEnabled = true
            defaults.set(true, forKey: CalendarAgendaDefaultsKey.isEnabled)
            errorMessage = nil
            return true
        } catch {
            disableWithError("无法访问 Calendar：\(error.localizedDescription)")
            return false
        }
    }

    func selectCalendar(
        _ selection: CalendarAgendaSelection,
        date: Date = Date(),
        now: Date = Date()
    ) {
        isEnabled = true
        selectedCalendarID = selection.id
        selectedCalendarTitle = selection.displayTitle
        defaults.set(true, forKey: CalendarAgendaDefaultsKey.isEnabled)
        defaults.set(selection.id, forKey: CalendarAgendaDefaultsKey.selectedCalendarID)
        defaults.set(selection.displayTitle, forKey: CalendarAgendaDefaultsKey.selectedCalendarTitle)
        reload(date: date, now: now)
    }

    func reload(date: Date = Date(), now: Date = Date()) {
        guard isEnabled else {
            events = []
            errorMessage = nil
            return
        }
        guard provider.hasFullAccess() else {
            events = []
            errorMessage = "未获得 Calendar 访问权限（当前状态：\(provider.accessStatusDescription())）"
            return
        }
        guard let selectedCalendarID else {
            events = []
            errorMessage = nil
            return
        }
        guard availableCalendars.contains(where: { $0.id == selectedCalendarID }) else {
            events = []
            errorMessage = "已选择的日历不可用，请重新选择"
            return
        }

        do {
            events = try provider.events(
                for: selectedCalendarID,
                on: date,
                now: now
            )
            lastReloadAt = now
            errorMessage = nil
        } catch CalendarAgendaError.calendarMissing {
            events = []
            errorMessage = "已选择的日历不可用，请重新选择"
        } catch {
            events = []
            errorMessage = "无法读取今日日程"
        }
    }

    func reloadIfStale(
        date: Date = Date(),
        now: Date = Date(),
        staleAfter interval: TimeInterval
    ) {
        guard isConfigured else { return }
        if let lastReloadAt, now.timeIntervalSince(lastReloadAt) < interval {
            return
        }
        reload(date: date, now: now)
    }

    func showError(_ message: String) {
        events = []
        errorMessage = message
    }

    private func disableWithError(_ message: String) {
        isEnabled = false
        events = []
        errorMessage = message
        defaults.set(false, forKey: CalendarAgendaDefaultsKey.isEnabled)
    }
}
