import Foundation
import SwiftData

enum WorkoutType: String, Codable, CaseIterable, Identifiable {
    case a = "Workout A"
    case b = "Workout B"

    var id: String { rawValue }

    var exercises: [String] {
        switch self {
        case .a:
            return ["Barbell Squat", "Barbell Bench Press", "Barbell Row"]
        case .b:
            return ["Barbell Squat", "Overhead Press", "Deadlift"]
        }
    }

    var accessorySlots: Int { 2 }

    mutating func toggle() {
        self = (self == .a) ? .b : .a
    }
}

@Model
final class Workout {
    var date: Date
    var typeRaw: String
    var duration: TimeInterval?
    var notes: String
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseRecord]

    var type: WorkoutType {
        get { WorkoutType(rawValue: typeRaw) ?? .a }
        set { typeRaw = newValue.rawValue }
    }

    init(date: Date = Date(), type: WorkoutType = .a, exercises: [ExerciseRecord] = [], duration: TimeInterval? = nil, notes: String = "") {
        self.date = date
        self.typeRaw = type.rawValue
        self.exercises = exercises
        self.duration = duration
        self.notes = notes
    }
}

@Model
final class ExerciseRecord {
    var exerciseName: String
    var isPrimary: Bool
    var sortOrder: Int
    @Relationship(deleteRule: .cascade) var sets: [SetRecord]
    @Relationship(deleteRule: .cascade) var warmupSets: [SetRecord]

    init(exerciseName: String, isPrimary: Bool = true, sortOrder: Int = 0, sets: [SetRecord] = [], warmupSets: [SetRecord] = []) {
        self.exerciseName = exerciseName
        self.isPrimary = isPrimary
        self.sortOrder = sortOrder
        self.sets = sets
        self.warmupSets = warmupSets
    }

    var isComplete: Bool {
        !sets.isEmpty && sets.allSatisfy { $0.isCompleted }
    }

    var targetReps: Int { 5 }
    var targetSets: Int { exerciseName == "Deadlift" ? 1 : 5 }

    /// Max weight across completed sets
    var maxCompletedWeight: Double? {
        sets.filter { $0.isCompleted }.map(\.weight).max()
    }

    /// Total volume (weight x completed reps)
    var totalVolume: Double {
        sets.filter { $0.isCompleted }.reduce(0) { $0 + ($1.weight * Double($1.completedReps)) }
    }
}

@Model
final class SetRecord {
    var weight: Double
    var reps: Int
    var completedReps: Int
    var isCompleted: Bool
    var sortOrder: Int

    init(weight: Double, reps: Int = 5, completedReps: Int? = nil, isCompleted: Bool = false, sortOrder: Int = 0) {
        self.weight = weight
        self.reps = reps
        self.completedReps = completedReps ?? reps
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
    }

    var isFailure: Bool {
        isCompleted && completedReps < reps
    }
}

@Model
final class Progression {
    var exerciseName: String
    var currentWeight: Double
    var incrementLbs: Double
    var deloadCount: Int
    var consecutiveFailures: Int
    var lastUpdated: Date?

    init(exerciseName: String, currentWeight: Double, incrementLbs: Double = 5, deloadCount: Int = 0, consecutiveFailures: Int = 0, lastUpdated: Date? = nil) {
        self.exerciseName = exerciseName
        self.currentWeight = currentWeight
        self.incrementLbs = incrementLbs
        self.deloadCount = deloadCount
        self.consecutiveFailures = consecutiveFailures
        self.lastUpdated = lastUpdated
    }

    var needsDeload: Bool { consecutiveFailures >= 3 }

    func recordSuccess() {
        currentWeight += incrementLbs
        consecutiveFailures = 0
        lastUpdated = Date()
    }

    func recordFailure() {
        consecutiveFailures += 1
        lastUpdated = Date()
    }

    func applyDeload() {
        currentWeight = max(currentWeight * 0.9, 45)
        consecutiveFailures = 0
        deloadCount += 1
        lastUpdated = Date()
    }
}

@Model
final class BodyWeightRecord {
    var date: Date
    var weight: Double
    var note: String?

    init(date: Date = Date(), weight: Double, note: String? = nil) {
        self.date = date
        self.weight = weight
        self.note = note
    }
}
