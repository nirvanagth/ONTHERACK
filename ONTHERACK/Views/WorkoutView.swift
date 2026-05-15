import SwiftUI

struct WorkoutLaunchView: View {
    @State private var viewModel: WorkoutViewModel

    init(viewModel: WorkoutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let workout = viewModel.activeWorkout {
                WorkoutActiveView(viewModel: viewModel, workout: workout)
            } else {
                NavigationStack {
                    WorkoutTypeSelectView(viewModel: viewModel)
                }
            }
        }
    }
}

struct WorkoutActiveView: View {
    @State private var viewModel: WorkoutViewModel
    let workout: Workout
    @State private var showingFinishAlert = false
    @State private var showingCancelAlert = false
    @State private var selectedTool: ToolType?
    @State private var showingRestTimer = false
    @State private var restTimerExerciseName: String?

    enum ToolType: String, Identifiable {
        case plates, warmup
        var id: String { rawValue }
    }

    init(viewModel: WorkoutViewModel, workout: Workout) {
        _viewModel = State(initialValue: viewModel)
        self.workout = workout
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text(workout.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(workout.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    ProgressView(value: Double(viewModel.activeWorkoutProgress.completed),
                                 total: Double(max(viewModel.activeWorkoutProgress.total, 1)))
                        .tint(.orangeRed)
                        .padding(.horizontal)
                    Text("\(viewModel.activeWorkoutProgress.completed) / \(viewModel.activeWorkoutProgress.total) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)

                // Exercise List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseCardView(
                                exercise: exercise,
                                isActive: index == viewModel.currentExerciseIndex,
                                onCompleteSet: { set, reps in
                                    viewModel.completeSet(set, completedReps: reps)
                                    viewModel.advanceAfterCompletingSet(at: index)
                                    if !viewModel.isAllExercisesComplete {
                                        restTimerExerciseName = exercise.exerciseName
                                        showingRestTimer = true
                                    }
                                },
                                onUndoSet: { set in
                                    viewModel.undoSet(set)
                                }
                            )
                        }
                    }
                    .padding()
                }

                // Bottom bar
                HStack(spacing: 16) {
                    Button {
                        selectedTool = .plates
                    } label: {
                        Image(systemName: "divide.square")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orangeRed)

                    Button {
                        selectedTool = .warmup
                    } label: {
                        Image(systemName: "thermometer")
                            .font(.title3)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orangeRed)

                    Spacer()

                    Button {
                        showingFinishAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Finish")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(viewModel.isAllExercisesComplete ? Color.orangeRed : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!viewModel.isAllExercisesComplete)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.cardDark)
            }
            .background(Color.surfaceDark.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showingCancelAlert = true
                    } label: {
                        Text("Cancel")
                            .foregroundColor(.orangeRed)
                    }
                }
            }
            .alert("Cancel Workout?", isPresented: $showingCancelAlert) {
                Button("Keep Training", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    viewModel.cancelWorkout()
                }
            } message: {
                Text("This workout will be deleted and your progressions won't be updated.")
            }
            .alert("Finish Workout?", isPresented: $showingFinishAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Finish", role: .destructive) {
                    viewModel.finishWorkout()
                }
            } message: {
                Text("All exercises completed. Save this workout and update your progress.")
            }
            .sheet(item: $selectedTool) { tool in
                switch tool {
                case .plates:
                    PlateCalculatorView()
                        .preferredColorScheme(.dark)
                case .warmup:
                    WarmupCalculatorView()
                        .preferredColorScheme(.dark)
                }
            }
            .sheet(isPresented: $showingRestTimer, onDismiss: {
                restTimerExerciseName = nil
            }) {
                RestTimerView(exerciseName: restTimerExerciseName)
                    .presentationDetents([.height(200)])
                    .preferredColorScheme(.dark)
            }
        }
    }
}

struct ExerciseCardView: View {
    let exercise: ExerciseRecord
    let isActive: Bool
    let onCompleteSet: (SetRecord, Int) -> Void
    let onUndoSet: (SetRecord) -> Void

    @State private var showingFailureDialog = false
    @State private var pendingFailureSet: SetRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                if exercise.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // Warmup sets (if any)
            if !exercise.warmupSets.isEmpty {
                HStack(spacing: 6) {
                    ForEach(exercise.warmupSets) { set in
                        Text("\(Int(set.weight))")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    Text("warmup")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Working sets
            ForEach(exercise.sets) { set in
                HStack {
                    Text("\(Int(set.weight)) lbs")
                        .fontWeight(.medium)
                        .frame(width: 70, alignment: .leading)

                    Text("x \(set.reps)")
                        .foregroundColor(.secondary)

                    Spacer()

                    if set.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                            if set.isFailure {
                                Text("(\(set.completedReps))")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            Button { onUndoSet(set) } label: {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack(spacing: 4) {
                            Button { onCompleteSet(set, set.reps) } label: {
                                Text("Done")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orangeRed)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                            Button {
                                pendingFailureSet = set
                                showingFailureDialog = true
                            } label: {
                                Text("Fail")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.3))
                                    .foregroundColor(.secondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(isActive ? Color.cardDark : Color.surfaceDark)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.orangeRed.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .confirmationDialog(
            "Reps completed",
            isPresented: $showingFailureDialog,
            titleVisibility: .visible
        ) {
            if let set = pendingFailureSet {
                ForEach(Array((0..<set.reps).reversed()), id: \.self) { reps in
                    Button("\(reps) reps") {
                        onCompleteSet(set, reps)
                        pendingFailureSet = nil
                    }
                }
            }

            Button("Cancel", role: .cancel) {
                pendingFailureSet = nil
            }
        } message: {
            Text("Record this set as failed.")
        }
    }
}
