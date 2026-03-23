import AppKit
import SwiftUI
import Combine

@MainActor
class FloatingPanelController: ObservableObject {
    @Published var isVisible = false

    private var panel: FloatingPanel?
    private var timerManager: TimerManager?
    private var startAction: () -> Void = {}

    init() {
        isVisible = UserDefaults.standard.bool(forKey: "floatingWindowVisible")
    }

    func setup(timerManager: TimerManager, startAction: @escaping @MainActor () -> Void = {}) {
        self.startAction = startAction
        self.timerManager = timerManager
        if isVisible {
            show()
        }
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func setVisible(_ visible: Bool) {
        if visible {
            show()
        } else {
            hide()
        }
    }

    private func show() {
        guard let timerManager else { return }

        if panel == nil {
            let frame = loadSavedFrame() ?? defaultFrame()
            panel = FloatingPanel(contentRect: frame)

            let hostingView = NSHostingView(
                rootView: FloatingTimerView(timerManager: timerManager, startAction: startAction)
            )
            panel?.contentView = hostingView

            NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification,
                object: panel,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.saveFrame()
                }
            }
        }

        panel?.orderFront(nil)
        isVisible = true
        UserDefaults.standard.set(true, forKey: "floatingWindowVisible")
    }

    private func hide() {
        saveFrame()
        panel?.orderOut(nil)
        isVisible = false
        UserDefaults.standard.set(false, forKey: "floatingWindowVisible")
    }

    private func defaultFrame() -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 0, y: 0, width: 200, height: 120)
        }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.maxX - 200 - 20
        let y = screenFrame.maxY - 80 - 20
        return NSRect(x: x, y: y, width: 200, height: 120)
    }

    private func saveFrame() {
        guard let frame = panel?.frame else { return }
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: "floatingPanelFrame")
    }

    private func loadSavedFrame() -> NSRect? {
        guard let str = UserDefaults.standard.string(forKey: "floatingPanelFrame") else {
            return nil
        }
        let rect = NSRectFromString(str)
        return rect.width > 0 ? rect : nil
    }
}
