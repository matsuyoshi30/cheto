import Foundation
import Testing
@testable import cheto

@Suite("TimerManager State Machine")
@MainActor
struct TimerManagerTests {
    @Test func initialState() {
        let manager = TimerManager()
        #expect(manager.currentPhase == .idle)
        #expect(manager.isRunning == false)
        #expect(manager.remainingSeconds == 0)
    }

    @Test func startBeginsWorking() {
        let manager = TimerManager()
        manager.start()
        #expect(manager.currentPhase == .working)
        #expect(manager.isRunning == true)
        #expect(manager.remainingSeconds == TimerManager.defaultWorkDuration)
    }

    @Test func pauseKeepsPhase() {
        let manager = TimerManager()
        manager.start()
        manager.pause()
        #expect(manager.currentPhase == .working)
        #expect(manager.isRunning == false)
    }

    @Test func resumeAfterPause() {
        let manager = TimerManager()
        manager.start()
        manager.pause()
        manager.resume()
        #expect(manager.currentPhase == .working)
        #expect(manager.isRunning == true)
    }

    @Test func skipFromWorkingToBreak() {
        let manager = TimerManager()
        manager.start()
        manager.skip()
        #expect(manager.currentPhase == .onBreak)
        #expect(manager.isRunning == true)
        #expect(manager.remainingSeconds == TimerManager.defaultBreakDuration)
    }

    @Test func skipFromBreakToIdle() {
        let manager = TimerManager()
        manager.start()
        manager.skip() // working -> onBreak
        manager.skip() // onBreak -> idle
        #expect(manager.currentPhase == .idle)
        #expect(manager.isRunning == false)
    }

    @Test func skipFromIdleDoesNothing() {
        let manager = TimerManager()
        manager.skip()
        #expect(manager.currentPhase == .idle)
        #expect(manager.isRunning == false)
    }

    @Test func resetFromAnyState() {
        let manager = TimerManager()
        manager.start()
        manager.reset()
        #expect(manager.currentPhase == .idle)
        #expect(manager.isRunning == false)
    }

    @Test func progressCalculation() {
        let manager = TimerManager()
        manager.start()
        #expect(manager.progress == 0.0)
    }

    @Test func sleepResilienceUsesEndDate() {
        let manager = TimerManager()
        manager.start()
        manager.setEndDateForTesting(Date().addingTimeInterval(10))
        manager.tickForTesting()
        #expect(manager.remainingSeconds <= 10)
        #expect(manager.remainingSeconds >= 9)
    }
}
