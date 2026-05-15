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
        // Auto-resume an in-progress workout if the app was killed mid-session.
        self.activeWorkout = workoutService.fetchUnfinishedWorkout()
    }

    // MARK: - Workout Lifecycle

    func startWorkout(from template: WorkoutTemplate) {
        let workout = workoutService.createWorkout(from: template)
        // Pre-fill sets based on progression + template
        for exercise in workout.exercises {
            let templateExercise = template.exercises.first(where: { $0.exerciseName == exercise.exerciseName })
            let targetSets = templateExercise?.targetSets ?? 5
            let targetReps = templateExercise?.targetReps ?? 5
            let weight = progressionService.fetchProgression(for: exercise.exerciseName)?.currentWeight ?? 45
            exercise.sets = (0..<targetSets).map { i in
                SetRecord(weight: weight, reps: targetReps, sortOrder: i)
            }
        }
        try? modelContext.save()
        activeWorkout = workout
        currentExerciseIndex = 0
    }

    func completeSet(_ set: SetRecord, completedReps: Int) {
        set.completedReps = min(max(completedReps, 0), set.reps)
        set.isCompleted = true
        try? modelContext.save()
    }

    func failSet(_ set: SetRecord, completedReps: Int) {
        completeSet(set, completedReps: min(completedReps, max(set.reps - 1, 0)))
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
        currentExerciseIndex = 0
    }

    func cancelWorkout() {
        guard let workout = activeWorkout else { return }
        workoutService.deleteWorkout(workout)
        activeWorkout = nil
        currentExerciseIndex = 0
    }

    var currentExercise: ExerciseRecord? {
        guard let workout = activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }

    func advanceAfterCompletingSet(at exerciseIndex: Int) {
        guard let workout = activeWorkout, !workout.exercises.isEmpty else {
            currentExerciseIndex = 0
            return
        }

        if let nextIncomplete = workout.exercises.indices.first(where: {
            $0 > exerciseIndex && !workout.exercises[$0].isComplete
        }) {
            currentExerciseIndex = nextIncomplete
            return
        }

        if let firstIncomplete = workout.exercises.indices.first(where: {
            !workout.exercises[$0].isComplete
        }) {
            currentExerciseIndex = firstIncomplete
            return
        }

        currentExerciseIndex = min(exerciseIndex, workout.exercises.count - 1)
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
