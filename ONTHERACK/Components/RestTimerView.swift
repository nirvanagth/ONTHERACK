import SwiftUI
import Combine

struct RestTimerView: View {
    let exerciseName: String?
    @State private var timeRemaining: Int
    @State private var isRunning = false
    @State private var cancellable: AnyCancellable?

    init(exerciseName: String? = nil) {
        self.exerciseName = exerciseName
        let initial = (exerciseName == "Deadlift") ? 180 : 90
        _timeRemaining = State(initialValue: initial)
    }

    private var defaultDuration: Int {
        (exerciseName == "Deadlift") ? 180 : 90
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Rest Timer")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(formattedTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(timeRemaining <= 10 ? .orangeRed : .primary)

            HStack(spacing: 20) {
                Button {
                    isRunning ? pause() : resume()
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.cardDark)
                        .clipShape(Circle())
                }

                Button("Skip") {
                    timeRemaining = 0
                }
                .buttonStyle(.bordered)
                .tint(.orangeRed)

                Button("+30s") {
                    timeRemaining += 30
                }
                .buttonStyle(.bordered)
                .tint(.orangeRed)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.surfaceDark)
        .onAppear { start() }
        .onDisappear { cancellable?.cancel() }
    }

    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func start() {
        timeRemaining = defaultDuration
        isRunning = true
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in tick() }
    }

    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            cancellable?.cancel()
            isRunning = false
        }
    }

    private func pause() {
        isRunning = false
        cancellable?.cancel()
        cancellable = nil
    }

    private func resume() {
        isRunning = true
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in tick() }
    }
}
