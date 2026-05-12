import Foundation
import SwiftData

final class ProgressionService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchProgression(for exerciseName: String) -> Progression? {
        let predicate = #Predicate<Progression> { $0.exerciseName == exerciseName }
        var descriptor = FetchDescriptor<Progression>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func fetchAllProgressions() -> [Progression] {
        let descriptor = FetchDescriptor<Progression>(sortBy: [SortDescriptor(\.exerciseName)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Record a completed 5x5 set for an exercise
    func recordCompletedExercise(_ exerciseName: String, sets: [SetRecord]) {
        guard let prog = fetchProgression(for: exerciseName) else { return }
        let hasFailure = sets.contains { $0.isFailure }
        let allFailed = sets.allSatisfy { !$0.isCompleted }

        if allFailed {
            prog.consecutiveFailures += 1
        } else if hasFailure {
            prog.consecutiveFailures += 1
        } else {
            // All sets completed successfully - progress
            prog.currentWeight += prog.incrementLbs
            prog.consecutiveFailures = 0
        }
        prog.lastUpdated = Date()
        try? modelContext.save()
    }

    /// Check if deload is needed and optionally apply it
    func checkAndApplyDeload(for exerciseName: String) -> Bool {
        guard let prog = fetchProgression(for: exerciseName), prog.needsDeload else {
            return false
        }
        prog.currentWeight = max(prog.currentWeight * 0.9, 45.0)
        prog.consecutiveFailures = 0
        prog.deloadCount += 1
        prog.lastUpdated = Date()
        try? modelContext.save()
        return true
    }

    // MARK: - Calculations

    /// Epley formula: 1RM = weight × (1 + reps / 30)
    static func estimate1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return weight }
        return weight * (1 + Double(reps) / 30.0)
    }

    /// Generate warmup sets for a given working weight
    static func warmupSets(for workingWeight: Double) -> [(label: String, weight: Double, reps: Int)] {
        guard workingWeight > 45 else { return [] }
        return [
            ("Bar", 45, 10),
            ("50%", (workingWeight * 0.5).roundedToFive, 5),
            ("70%", (workingWeight * 0.7).roundedToFive, 3),
            ("Working", workingWeight, 1),
        ]
    }

    /// Calculate plate count for each side (standard 45lb bar)
    static func platesForWeight(_ total: Double, barWeight: Double = 45) -> [(weight: Double, count: Int)] {
        let perSide = (total - barWeight) / 2
        guard perSide > 0 else { return [] }

        let availablePlates: [Double] = [45, 25, 10, 5, 2.5]
        var remaining = perSide
        var result: [(Double, Int)] = []

        for plate in availablePlates {
            let count = Int(remaining / plate)
            if count > 0 {
                result.append((plate, count))
                remaining -= Double(count) * plate
            }
        }
        return result
    }
}

extension Double {
    var roundedToFive: Double {
        (self / 5).rounded(.toNearestOrAwayFromZero) * 5
    }
}
