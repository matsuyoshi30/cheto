import EventKit
import Foundation

@MainActor
class CalendarManager {
    private let store = EKEventStore()

    private let selectedCalendarIDsKey = "selectedCalendarIDs"

    /// Whether calendar access is granted
    var hasAccess: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// Request calendar access (macOS shows a system dialog on first call)
    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    /// Available calendars (event type only)
    var availableCalendars: [EKCalendar] {
        guard hasAccess else { return [] }
        return store.calendars(for: .event)
    }

    /// Calendar IDs selected for pre-pomodoro check
    var selectedCalendarIDs: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: selectedCalendarIDsKey) ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: selectedCalendarIDsKey)
        }
    }

    /// Return the nearest event starting within the given seconds (excludes all-day events).
    /// Returns nil if access is not granted or no calendars are selected.
    func nextEvent(within seconds: Int) -> EKEvent? {
        guard hasAccess else { return nil }

        let ids = selectedCalendarIDs
        guard !ids.isEmpty else { return nil }

        let calendars = store.calendars(for: .event).filter { ids.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return nil }

        let now = Date()
        // predicateForEvents uses a half-open interval [start, end),
        // so add 1 second to include events starting exactly at the boundary
        let end = now.addingTimeInterval(TimeInterval(seconds + 1))
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: calendars)
        let events = store.events(matching: predicate)

        // Exclude all-day events and return the one with the earliest start time
        return events
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .first
    }
}
