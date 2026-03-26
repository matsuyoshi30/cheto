import UserNotifications
import AppKit

@MainActor
class NotificationManager: ObservableObject {
    /// Whether UNUserNotificationCenter is available (requires a proper .app bundle)
    private var notificationsAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    /// Number of times to repeat the notification sound
    private let soundRepeatCount = 3
    /// Interval between each sound repetition (seconds)
    private let soundRepeatInterval: TimeInterval = 1.0

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

    private var soundTimer: Timer?
    private var soundPlayCount = 0

    /// Play the notification sound multiple times so it's easier to notice.
    /// Uses a repeating Timer for consistent intervals between plays.
    func playSound() {
        soundPlayCount = 0
        playSoundOnce()
        soundTimer = Timer.scheduledTimer(withTimeInterval: soundRepeatInterval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            Task { @MainActor in
                self.soundPlayCount += 1
                if self.soundPlayCount >= self.soundRepeatCount - 1 {
                    timer.invalidate()
                    self.soundTimer = nil
                }
                self.playSoundOnce()
            }
        }
    }

    private func playSoundOnce() {
        guard let sound = NSSound(named: "Purr") else { return }
        let copy = sound.copy() as! NSSound
        copy.play()
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
