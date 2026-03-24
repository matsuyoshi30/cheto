import SwiftUI
import Combine

@main
struct chetoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene — menu bar is managed by AppDelegate via NSStatusItem
        Settings { EmptyView() }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timerManager: TimerManager!
    private var notificationManager: NotificationManager!
    private var panelController: FloatingPanelController!
    private var cancellables = Set<AnyCancellable>()
    private var calendarManager: CalendarManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        timerManager = TimerManager()
        notificationManager = NotificationManager()
        calendarManager = CalendarManager()
        panelController = FloatingPanelController()

        panelController.setup(timerManager: timerManager, startAction: { [weak self] in
            self?.startWithCalendarCheck()
        })
        timerManager.onPhaseComplete = { [weak self] phase in
            self?.notificationManager.handlePhaseComplete(phase)
        }
        notificationManager.requestPermission()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🍅"

        buildMenu()

        // Update menu bar title and menu items on timer changes
        timerManager.$remainingSeconds
            .merge(with: timerManager.$currentPhase.map { _ in 0 })
            .merge(with: timerManager.$isRunning.map { _ in 0 })
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
                self?.buildMenu()
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem() {
        if timerManager.currentPhase == .idle {
            statusItem.button?.title = "🍅"
        } else {
            statusItem.button?.title = "🍅 \(timerManager.formattedTime)"
        }
    }

    private func buildMenu() {
        let menu = NSMenu()

        if timerManager.currentPhase == .idle {
            menu.addItem(NSMenuItem(title: "Start", action: #selector(startTimer), keyEquivalent: ""))
        } else {
            // Phase + time display (disabled item)
            let statusItem = NSMenuItem(title: "\(phaseLabel) — \(timerManager.formattedTime)", action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)

            menu.addItem(.separator())

            if timerManager.isRunning {
                menu.addItem(NSMenuItem(title: "Pause", action: #selector(pauseTimer), keyEquivalent: ""))
            } else {
                menu.addItem(NSMenuItem(title: "Resume", action: #selector(resumeTimer), keyEquivalent: ""))
            }
            menu.addItem(NSMenuItem(title: "Skip", action: #selector(skipTimer), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Reset", action: #selector(resetTimer), keyEquivalent: ""))
        }

        menu.addItem(.separator())

        let floatingItem = NSMenuItem(title: "Floating Window", action: #selector(toggleFloating), keyEquivalent: "")
        floatingItem.state = panelController.isVisible ? .on : .off
        menu.addItem(floatingItem)

        menu.addItem(.separator())

        // Calendar settings
        if calendarManager.hasAccess {
            let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
            let settingsMenu = NSMenu()

            let calendarsItem = NSMenuItem(title: "Calendars", action: nil, keyEquivalent: "")
            let calendarsMenu = NSMenu()

            let selectedIDs = calendarManager.selectedCalendarIDs
            for calendar in calendarManager.availableCalendars {
                let item = NSMenuItem(
                    title: calendar.title,
                    action: #selector(toggleCalendar(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = calendar.calendarIdentifier
                item.state = selectedIDs.contains(calendar.calendarIdentifier) ? .on : .off
                calendarsMenu.addItem(item)
            }

            calendarsItem.submenu = calendarsMenu
            settingsMenu.addItem(calendarsItem)
            settingsItem.submenu = settingsMenu
            menu.addItem(settingsItem)
        } else {
            let enableItem = NSMenuItem(
                title: "Enable Calendar Check…",
                action: #selector(requestCalendarAccess),
                keyEquivalent: ""
            )
            enableItem.target = self
            menu.addItem(enableItem)
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        // Set target for all actionable items
        for item in menu.items where item.action != nil {
            item.target = self
        }

        self.statusItem.menu = menu
    }

    private var phaseLabel: String {
        switch timerManager.currentPhase {
        case .idle: return "Ready"
        case .working: return "Working"
        case .onBreak: return "Break"
        }
    }

    @objc private func startTimer() { startWithCalendarCheck() }
    @objc private func pauseTimer() { timerManager.pause() }
    @objc private func resumeTimer() { timerManager.resume() }
    @objc private func skipTimer() { timerManager.skip() }
    @objc private func resetTimer() { timerManager.reset() }
    @objc private func toggleFloating() { panelController.toggle() }
    private func startWithCalendarCheck() {
        guard calendarManager.hasAccess, !calendarManager.selectedCalendarIDs.isEmpty else {
            timerManager.start()
            return
        }

        guard let event = calendarManager.nextEvent(within: TimerManager.defaultWorkDuration) else {
            timerManager.start()
            return
        }

        let minutesUntil = max(1, Int(ceil(event.startDate.timeIntervalSinceNow / 60)))
        let title = event.title.map { $0.count > 40 ? String($0.prefix(40)) + "…" : $0 } ?? "予定"

        NSApp.activate()

        let alert = NSAlert()
        alert.messageText = "予定が近づいています"
        alert.informativeText = "\(minutesUntil)分後に \"\(title)\" があります。ポモドーロを開始しますか？"
        alert.addButton(withTitle: "開始")
        alert.addButton(withTitle: "キャンセル")
        alert.alertStyle = .warning

        if alert.runModal() == .alertFirstButtonReturn {
            timerManager.start()
        }
    }

    @objc private func toggleCalendar(_ sender: NSMenuItem) {
        guard let calendarID = sender.representedObject as? String else { return }
        var ids = calendarManager.selectedCalendarIDs
        if ids.contains(calendarID) {
            ids.remove(calendarID)
        } else {
            ids.insert(calendarID)
        }
        calendarManager.selectedCalendarIDs = ids
    }

    @objc private func requestCalendarAccess() {
        Task {
            _ = await calendarManager.requestAccess()
            buildMenu()
        }
    }

    @objc private func quitApp() { NSApplication.shared.terminate(nil) }
}
