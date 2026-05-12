import SwiftUI
import Charts

struct HistoryView: View {
    @State private var viewModel: WorkoutViewModel
    @State private var workouts: [Workout] = []
    @State private var selectedExercise: String = "Barbell Squat"
    @State private var showingChart = false

    let allExercises = ["Barbell Squat", "Barbell Bench Press", "Barbell Row", "Overhead Press", "Deadlift"]

    init(viewModel: WorkoutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Progress")
                                .font(.headline)
                            Spacer()
                            Picker("Exercise", selection: $selectedExercise) {
                                ForEach(allExercises, id: \.self) { name in
                                    Text(name).tag(name)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.orangeRed)
                        }

                        let data = viewModel.weightHistory(for: selectedExercise)
                        if data.isEmpty {
                            Text("No data yet. Complete a workout to see your progress.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            weightChart(data: data)
                        }
                    }
                    .padding()
                    .background(Color.cardDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    // Workout History
                    Text("Workout History")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    if workouts.isEmpty {
                        ContentUnavailableView(
                            "No Workouts Yet",
                            systemImage: "dumbbell",
                            description: Text("Complete your first 5x5 session to see it here.")
                        )
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(workouts) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(workout.displayName)
                                                .font(.headline)
                                            Text(workout.date, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            let completed = workout.exercises.filter { $0.isComplete }.count
                                            Text("\(completed)/\(workout.exercises.count) exercises")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            if let d = workout.duration {
                                                Text(formatDuration(d))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.orangeRed)
                                            .font(.caption)
                                    }
                                    .padding()
                                    .background(Color.cardDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.surfaceDark.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("History")
            .onAppear {
                workouts = viewModel.recentWorkouts()
            }
        }
    }

    private func weightChart(data: [(date: Date, weight: Double)]) -> some View {
        Chart {
            ForEach(data, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Color.orangeRed)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Weight", point.weight)
                )
                .foregroundStyle(Color.orangeRed)
                .symbolSize(20)
            }
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))")
                            .font(.caption2)
                    }
                }
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(workout.displayName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(workout.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let d = workout.duration {
                    Text("Duration: \(Int(d)/60) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ForEach(workout.exercises) { exercise in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(exercise.exerciseName)
                                .font(.headline)
                            Spacer()
                            Text("\(exercise.totalVolume, specifier: "%.0f") lbs volume")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        ForEach(exercise.sets) { set in
                            HStack {
                                Text("\(Int(set.weight)) lbs")
                                Text("x \(set.completedReps)")
                                    .foregroundColor(.secondary)
                                Spacer()
                                if set.isCompleted {
                                    if set.isFailure {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    } else {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(set.isCompleted ? (set.isFailure ? Color.orange.opacity(0.1) : Color.green.opacity(0.1)) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .padding()
                    .background(Color.cardDark)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color.surfaceDark.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
