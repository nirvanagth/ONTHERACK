import SwiftUI
import SwiftData

@main
struct ONTHERACKApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Workout.self,
                ExerciseRecord.self,
                SetRecord.self,
                Progression.self,
                BodyWeightRecord.self,
                WorkoutTemplate.self,
                TemplateExercise.self,
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)

            // Pre-populate default progression if first launch
            let context = ModelContext(container)
            seedDefaultProgressionsIfNeeded(context: context)
            seedDefaultTemplatesIfNeeded(context: context)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }

    private func seedDefaultProgressionsIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Progression>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let defaults: [(String, Double)] = [
            ("Barbell Squat", 135),
            ("Barbell Bench Press", 95),
            ("Barbell Row", 95),
            ("Overhead Press", 65),
            ("Deadlift", 185),
        ]
        for (name, weight) in defaults {
            context.insert(Progression(
                exerciseName: name,
                currentWeight: weight,
                incrementLbs: 5,
                deloadCount: 0,
                consecutiveFailures: 0
            ))
        }
        try? context.save()
    }

    private func seedDefaultTemplatesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<WorkoutTemplate>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let templates: [(String, [(String, Int, Int)])] = [
            ("Workout A", [
                ("Barbell Squat", 5, 5),
                ("Barbell Bench Press", 5, 5),
                ("Barbell Row", 5, 5),
            ]),
            ("Workout B", [
                ("Barbell Squat", 5, 5),
                ("Overhead Press", 5, 5),
                ("Deadlift", 1, 5),
            ]),
        ]
        for (i, (name, exercises)) in templates.enumerated() {
            let template = WorkoutTemplate(name: name, sortOrder: i)
            for (j, (exName, sets, reps)) in exercises.enumerated() {
                template.exercises.append(TemplateExercise(
                    exerciseName: exName,
                    targetSets: sets,
                    targetReps: reps,
                    sortOrder: j,
                    isAccessory: false
                ))
            }
            context.insert(template)
        }
        try? context.save()
    }
}
