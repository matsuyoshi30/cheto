import EventKit
import Foundation

@MainActor
class CalendarManager {
    private let store = EKEventStore()

    private let selectedCalendarIDsKey = "selectedCalendarIDs"

    /// アクセスが許可されているか
    var hasAccess: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// アクセス権限をリクエスト（初回は macOS がシステムダイアログを表示）
    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    /// 利用可能なカレンダー一覧（イベントタイプのみ）
    var availableCalendars: [EKCalendar] {
        guard hasAccess else { return [] }
        return store.calendars(for: .event)
    }

    /// チェック対象として選択されたカレンダーID
    var selectedCalendarIDs: Set<String> {
        get {
            let array = UserDefaults.standard.stringArray(forKey: selectedCalendarIDsKey) ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: selectedCalendarIDsKey)
        }
    }

    /// 指定秒数以内に開始する最も近いイベントを返す（終日イベント除外）
    /// hasAccess == false または selectedCalendarIDs が空の場合は nil を返す
    func nextEvent(within seconds: Int) -> EKEvent? {
        guard hasAccess else { return nil }

        let ids = selectedCalendarIDs
        guard !ids.isEmpty else { return nil }

        let calendars = store.calendars(for: .event).filter { ids.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return nil }

        let now = Date()
        // EventKit の predicateForEvents は半開区間 [start, end) のため、
        // ちょうど seconds 秒後の予定を含めるために +1 秒する
        let end = now.addingTimeInterval(TimeInterval(seconds + 1))
        let predicate = store.predicateForEvents(withStart: now, end: end, calendars: calendars)
        let events = store.events(matching: predicate)

        // 終日イベントを除外し、開始時刻が最も近いものを返す
        return events
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .first
    }
}
