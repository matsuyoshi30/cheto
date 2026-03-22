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

    func applicationDidFinishLaunching(_ notification: Notification) {
        timerManager = TimerManager()
        notificationManager = NotificationManager()
        panelController = FloatingPanelController()

        panelController.setup(timerManager: timerManager)
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

    @objc private func startTimer() { timerManager.start() }
    @objc private func pauseTimer() { timerManager.pause() }
    @objc private func resumeTimer() { timerManager.resume() }
    @objc private func skipTimer() { timerManager.skip() }
    @objc private func resetTimer() { timerManager.reset() }
    @objc private func toggleFloating() { panelController.toggle() }
    @objc private func quitApp() { NSApplication.shared.terminate(nil) }
}
