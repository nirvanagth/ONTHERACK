import Foundation
import SwiftData

final class WorkoutService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Workout CRUD

    func createWorkout(from template: WorkoutTemplate) -> Workout {
        let exercises = template.exercises
            .sorted(by: { $0.sortOrder < $1.sortOrder })
            .map { tex in
                ExerciseRecord(
                    exerciseName: tex.exerciseName,
                    isPrimary: !tex.isAccessory,
                    sortOrder: tex.sortOrder
                )
            }
        // typeRaw is kept for backward compat with older records — new code paths
        // read the canonical label from templateName.
        let workout = Workout(
            type: .a,
            templateName: template.name,
            exercises: exercises
        )
        modelContext.insert(workout)
        return workout
    }

    // MARK: - Templates

    func fetchTemplates() -> [WorkoutTemplate] {
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func createTemplate(name: String) -> WorkoutTemplate {
        let nextOrder = (fetchTemplates().map(\.sortOrder).max() ?? -1) + 1
        let template = WorkoutTemplate(name: name, sortOrder: nextOrder)
        modelContext.insert(template)
        try? modelContext.save()
        return template
    }

    func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
    }

    func saveTemplateChanges() {
        try? modelContext.save()
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

    /// Finds the most recent workout with no recorded duration — i.e. one that
    /// was started but never explicitly finished. Used to resume after a kill.
    func fetchUnfinishedWorkout() -> Workout? {
        let predicate = #Predicate<Workout> { $0.duration == nil }
        var descriptor = FetchDescriptor<Workout>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)
        try? modelContext.save()
    }
}
