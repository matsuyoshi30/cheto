import Foundation
import Combine

enum TimerPhase {
    case idle
    case working
    case onBreak
}

@MainActor
class TimerManager: ObservableObject {
    static let defaultWorkDuration = 1500  // 25 minutes
    static let defaultBreakDuration = 300  // 5 minutes

    @Published var currentPhase: TimerPhase = .idle
    @Published var isRunning = false
    @Published var remainingSeconds = 0

    var totalSeconds: Int {
        switch currentPhase {
        case .idle: return 0
        case .working: return Self.defaultWorkDuration
        case .onBreak: return Self.defaultBreakDuration
        }
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0.0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    private var endDate: Date?
    private var timerCancellable: AnyCancellable?

    /// Called when a phase completes. Set by the app to trigger notifications.
    var onPhaseComplete: ((TimerPhase) -> Void)?

    func start() {
        currentPhase = .working
        remainingSeconds = Self.defaultWorkDuration
        isRunning = true
        startCountdown()
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
        endDate = nil
    }

    func resume() {
        guard !isRunning, currentPhase != .idle else { return }
        isRunning = true
        startCountdown()
    }

    func skip() {
        switch currentPhase {
        case .idle:
            return
        case .working:
            timerCancellable?.cancel()
            transitionToBreak()
        case .onBreak:
            timerCancellable?.cancel()
            transitionToIdle()
        }
    }

    func reset() {
        timerCancellable?.cancel()
        timerCancellable = nil
        endDate = nil
        currentPhase = .idle
        isRunning = false
        remainingSeconds = 0
    }

    // MARK: - Testing helpers

    func setEndDateForTesting(_ date: Date) {
        endDate = date
    }

    func tickForTesting() {
        tick()
    }

    // MARK: - Private

    private func startCountdown() {
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard let endDate else { return }
        let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
        if remaining <= 0 {
            timerCancellable?.cancel()
            timerCancellable = nil
            let completedPhase = currentPhase
            switch currentPhase {
            case .working:
                transitionToBreak()
            case .onBreak:
                transitionToIdle()
            case .idle:
                break
            }
            onPhaseComplete?(completedPhase)
        } else {
            remainingSeconds = remaining
        }
    }

    private func transitionToBreak() {
        currentPhase = .onBreak
        remainingSeconds = Self.defaultBreakDuration
        isRunning = true
        endDate = nil
        startCountdown()
    }

    private func transitionToIdle() {
        currentPhase = .idle
        isRunning = false
        remainingSeconds = 0
        endDate = nil
    }
}
