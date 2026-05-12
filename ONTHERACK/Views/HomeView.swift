import SwiftUI

struct HomeView: View {
    @State private var viewModel: WorkoutViewModel
    @State private var lastWorkout: Workout?
    @State private var thisWeekCount = 0

    init(viewModel: WorkoutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 4) {
                        Text("ONTHERACK")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.orangeRed)
                        Text("5x5 Training Log")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Start Training Button
                    NavigationLink {
                        WorkoutTypeSelectView(viewModel: viewModel)
                    } label: {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                            Text("Start Today's Workout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orangeRed)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)

                    // Last Workout Summary
                    if let last = lastWorkout {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.orangeRed)
                                Text("Last Workout")
                                    .font(.headline)
                                Spacer()
                                Text(last.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(last.displayName)
                                .font(.title3)
                                .fontWeight(.medium)

                            ForEach(last.exercises) { exercise in
                                HStack {
                                    Text(exercise.exerciseName)
                                        .font(.subheadline)
                                    Spacer()
                                    if let maxW = exercise.maxCompletedWeight {
                                        Text("\(maxW, specifier: "%.0f") lbs")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orangeRed)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.cardDark)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }

                    // Weekly Summary
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orangeRed)
                            Text("This Week")
                                .font(.headline)
                            Spacer()
                            Text("\(thisWeekCount) workouts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 0) {
                            ForEach(0..<7, id: \.self) { dayOffset in
                                let day = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
                                let didWorkout = viewModel.workoutService.workoutsOnDate(day).count > 0
                                VStack(spacing: 4) {
                                    Text(day, format: .dateTime.weekday(.narrow))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Circle()
                                        .fill(didWorkout ? Color.orangeRed : Color.gray.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                }
                                if dayOffset < 6 {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    // Quick Stats
                    LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                        StatCard(title: "5x5 Sessions", value: "\(viewModel.recentWorkouts().count)", icon: "figure.strengthtraining.traditional")
                        StatCard(title: "Best Lift", value: bestLiftString(), icon: "flame.fill")
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.surfaceDark.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .onAppear {
                loadData()
            }
        }
    }

    private func loadData() {
        lastWorkout = viewModel.lastWorkout()
        let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        thisWeekCount = viewModel.workoutService.fetchWorkoutsInRange(from: weekStart, to: Date()).count
    }

    private func bestLiftString() -> String {
        let progressions = viewModel.progressionService.fetchAllProgressions()
        guard let best = progressions.max(by: { $0.currentWeight < $1.currentWeight }) else {
            return "---"
        }
        return "\(best.exerciseName.split(separator: " ").last ?? "") \(Int(best.currentWeight))"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orangeRed)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardDark)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - WorkoutService extension for date filtering
extension WorkoutService {
    func workoutsOnDate(_ date: Date) -> [Workout] {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return fetchWorkoutsInRange(from: start, to: end)
    }
}

struct WorkoutTypeSelectView: View {
    @State private var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var templates: [WorkoutTemplate] = []

    init(viewModel: WorkoutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Select Workout")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 8)

                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Workout Plans",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Tap “Edit Workouts” to create your first plan.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(templates) { template in
                        Button {
                            viewModel.startWorkout(from: template)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name)
                                        .font(.headline)
                                    ForEach(template.exercises.sorted(by: { $0.sortOrder < $1.sortOrder })) { ex in
                                        Text("• \(ex.exerciseName)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.orangeRed)
                            }
                            .padding()
                            .background(Color.cardDark)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }

                NavigationLink {
                    PlanListView(viewModel: viewModel) {
                        // Refresh after returning so renames/adds show.
                        templates = viewModel.workoutService.fetchTemplates()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Edit Workouts")
                    }
                    .font(.subheadline)
                    .foregroundColor(.orangeRed)
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
        }
        .background(Color.surfaceDark.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { templates = viewModel.workoutService.fetchTemplates() }
    }
}
