import SwiftUI

struct WarmupCalculatorView: View {
    @State private var workingWeight: String = ""
    @State private var selectedExercise = "Barbell Squat"
    @State private var barWeight: Double = 45

    let exercises = ["Barbell Squat", "Barbell Bench Press", "Barbell Row", "Overhead Press", "Deadlift"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Warmup Calculator")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    Picker("Exercise", selection: $selectedExercise) {
                        ForEach(exercises, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.orangeRed)

                    TextField("Working weight (lbs)", text: $workingWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.black)
                }
                .padding(.horizontal)

                if let weight = Double(workingWeight), weight > barWeight {
                    let warmups = ProgressionService.warmupSets(for: weight)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Warmup Protocol")
                            .font(.headline)

                        HStack {
                            Text("Working Set:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(weight)) lbs x 5x5")
                                .fontWeight(.bold)
                                .foregroundColor(.orangeRed)
                        }
                        .padding(.bottom, 4)

                        ForEach(warmups, id: \.label) { warmup in
                            HStack {
                                Text(warmup.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                Text("\(Int(warmup.weight)) lbs")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("x \(warmup.reps)")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cardDark)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Divider()
                            .background(Color.gray.opacity(0.3))

                        Text("Tip: Don't fatigue yourself on warmups. The goal is to activate, not exhaust.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.surfaceDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                } else {
                    ContentUnavailableView(
                        "Enter working weight",
                        systemImage: "thermometer",
                        description: Text("Enter a weight greater than \(Int(barWeight)) lbs to see warmup sets.")
                    )
                }

                Spacer()
            }
            .padding(.top)
            .background(Color.surfaceDark)
            .preferredColorScheme(.dark)
        }
    }
}
