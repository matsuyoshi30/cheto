import SwiftUI

struct FloatingTimerView: View {
    @ObservedObject var timerManager: TimerManager

    @State private var highlightColor: Color?

    var body: some View {
        VStack(spacing: 8) {
            // Phase label
            Text(phaseLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            // Time
            Text(timerManager.formattedTime)
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressColor)
                        .frame(width: geo.size.width * timerManager.progress)
                        .animation(.linear(duration: 1), value: timerManager.progress)
                }
            }
            .frame(height: 4)

            // Control buttons
            HStack(spacing: 12) {
                if timerManager.currentPhase == .idle {
                    Button(action: { timerManager.start() }) {
                        Image(systemName: "play.fill")
                    }
                } else {
                    if timerManager.isRunning {
                        Button(action: { timerManager.pause() }) {
                            Image(systemName: "pause.fill")
                        }
                    } else {
                        Button(action: { timerManager.resume() }) {
                            Image(systemName: "play.fill")
                        }
                    }

                    Button(action: { timerManager.skip() }) {
                        Image(systemName: "forward.fill")
                    }

                    Button(action: { timerManager.reset() }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.8))
            .font(.system(size: 14))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(width: 200, height: 120)
        .background(backgroundColor)
        .shadow(color: glowColor, radius: highlightColor != nil ? 15 : 0)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onChange(of: timerManager.currentPhase) { oldPhase, newPhase in
            handlePhaseChange(from: oldPhase, to: newPhase)
        }
    }

    private var phaseLabel: String {
        switch timerManager.currentPhase {
        case .idle: return "Ready"
        case .working: return "🍅 Working"
        case .onBreak: return "☕ Break"
        }
    }

    private var progressColor: Color {
        switch timerManager.currentPhase {
        case .idle: return .gray
        case .working: return .red
        case .onBreak: return .green
        }
    }

    private var backgroundColor: Color {
        if let color = highlightColor {
            return color
        }
        return Color(red: 30/255, green: 30/255, blue: 46/255).opacity(0.92)
    }

    private var glowColor: Color {
        if let color = highlightColor {
            return color.opacity(0.6)
        }
        return .clear
    }

    private func handlePhaseChange(from oldPhase: TimerPhase, to newPhase: TimerPhase) {
        switch (oldPhase, newPhase) {
        case (.working, .onBreak):
            withAnimation(.easeIn(duration: 0.3)) {
                highlightColor = Color.green.opacity(0.85)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    highlightColor = nil
                }
            }
        case (.onBreak, .idle):
            withAnimation(.easeIn(duration: 0.3)) {
                highlightColor = Color.blue.opacity(0.85)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    highlightColor = nil
                }
            }
        default:
            break
        }
    }
}
