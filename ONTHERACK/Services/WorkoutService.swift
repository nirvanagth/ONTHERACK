import Foundation
import SwiftData

final class WorkoutService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Workout CRUD

    func createWorkout(type: WorkoutType) -> Workout {
        let exercises = type.exercises.map { name in
            ExerciseRecord(exerciseName: name, isPrimary: true, sortOrder: type.exercises.firstIndex(of: name)!)
        }
        let workout = Workout(type: type, exercises: exercises)
        modelContext.insert(workout)
        return workout
    }

    func fetchRecentWorkouts(limit: Int = 20) -> [Workout] {
        var descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchLastWorkout() -> Workout? {
        var descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func fetchWorkoutsForExercise(_ exerciseName: String, limit: Int = 30) -> [Workout] {
        var descriptor = FetchDescriptor<Workout>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        guard let workouts = try? modelContext.fetch(descriptor) else { return [] }
        return workouts.filter { $0.exercises.contains { $0.exerciseName == exerciseName } }
    }

    func fetchWorkoutsInRange(from: Date, to: Date) -> [Workout] {
        let predicate = #Predicate<Workout> { workout in
            workout.date >= from && workout.date <= to
        }
        var descriptor = FetchDescriptor<Workout>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
