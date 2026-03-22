import UserNotifications
import AppKit

@MainActor
class NotificationManager: ObservableObject {
    /// Whether UNUserNotificationCenter is available (requires a proper .app bundle)
    private var notificationsAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    func requestPermission() {
        guard notificationsAvailable else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }

    func sendNotification(title: String, body: String) {
        guard notificationsAvailable else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func playSound() {
        NSSound(named: "Purr")?.play()
    }

    func handlePhaseComplete(_ phase: TimerPhase) {
        switch phase {
        case .working:
            sendNotification(title: "Work Complete!", body: "Time for a break.")
            playSound()
        case .onBreak:
            sendNotification(title: "Break Over!", body: "Ready to get back to work.")
            playSound()
        case .idle:
            break
        }
    }
}
