import Foundation
import SwiftData
import Observation
import SwiftUI

@Observable
final class WorkoutViewModel {
    private let modelContext: ModelContext
    let workoutService: WorkoutService
    let progressionService: ProgressionService

    var activeWorkout: Workout?
    var selectedTab: Int = 0
    var showingPlateCalculator = false
    var showingWarmupCalculator = false
    /// Currently selected exercise index in active workout
    var currentExerciseIndex: Int = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.workoutService = WorkoutService(modelContext: modelContext)
        self.progressionService = ProgressionService(modelContext: modelContext)
    }

    // MARK: - Workout Lifecycle

    func startWorkout(type: WorkoutType) {
        let workout = workoutService.createWorkout(type: type)
        // Pre-fill sets based on progression
        for exercise in workout.exercises {
            guard let prog = progressionService.fetchProgression(for: exercise.exerciseName) else {
                // Default sets for unknown exercises
                let targetSets = exercise.exerciseName == "Deadlift" ? 1 : 5
                exercise.sets = (0..<targetSets).map { i in
                    SetRecord(weight: 45, reps: 5, sortOrder: i)
                }
                continue
            }
            let targetSets = exercise.exerciseName == "Deadlift" ? 1 : 5
            exercise.sets = (0..<targetSets).map { i in
                SetRecord(weight: prog.currentWeight, reps: 5, sortOrder: i)
            }
        }
        activeWorkout = workout
        currentExerciseIndex = 0
    }

    func completeSet(_ set: SetRecord, completedReps: Int) {
        set.completedReps = completedReps
        set.isCompleted = true
        try? modelContext.save()
        NotificationCenter.default.post(name: .setCompleted, object: set)
    }

    func failSet(_ set: SetRecord) {
        set.isCompleted = false
        set.completedReps = 0
        try? modelContext.save()
    }

    func undoSet(_ set: SetRecord) {
        set.isCompleted = false
        set.completedReps = set.reps
        try? modelContext.save()
    }

    func finishWorkout() {
        guard let workout = activeWorkout else { return }
        workout.duration = workout.date.distance(to: Date())

        // Update progressions
        for exercise in workout.exercises where exercise.isPrimary {
            progressionService.recordCompletedExercise(exercise.exerciseName, sets: exercise.sets)
            _ = progressionService.checkAndApplyDeload(for: exercise.exerciseName)
        }

        try? modelContext.save()
        activeWorkout = nil
    }

    var currentExercise: ExerciseRecord? {
        guard let workout = activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }

    var activeWorkoutProgress: (completed: Int, total: Int) {
        guard let workout = activeWorkout else { return (0, 0) }
        let allSets = workout.exercises.flatMap(\.sets)
        let completed = allSets.filter(\.isCompleted).count
        return (completed, allSets.count)
    }

    var isAllExercisesComplete: Bool {
        guard let workout = activeWorkout else { return false }
        return workout.exercises.allSatisfy(\.isComplete)
    }

    // MARK: - History

    func weightHistory(for exerciseName: String) -> [(date: Date, weight: Double)] {
        let workouts = workoutService.fetchWorkoutsForExercise(exerciseName)
        return workouts.compactMap { workout in
            guard let exercise = workout.exercises.first(where: { $0.exerciseName == exerciseName }),
                  let maxWeight = exercise.maxCompletedWeight else { return nil }
            return (workout.date, maxWeight)
        }
    }

    func recentWorkouts() -> [Workout] {
        workoutService.fetchRecentWorkouts()
    }

    func lastWorkout() -> Workout? {
        workoutService.fetchLastWorkout()
    }
}
