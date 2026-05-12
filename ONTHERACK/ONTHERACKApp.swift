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
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
            
            // Pre-populate default progression if first launch
            let context = ModelContext(container)
            seedDefaultProgressionsIfNeeded(context: context)
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
}
