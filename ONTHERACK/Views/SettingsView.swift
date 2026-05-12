import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var viewModel: WorkoutViewModel
    @State private var progressions: [Progression] = []

    init(viewModel: WorkoutViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Exercise Weights
                Section("Current Weights") {
                    ForEach(progressions) { prog in
                        HStack {
                            Text(prog.exerciseName)
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(prog.currentWeight)) lbs")
                                .fontWeight(.semibold)
                                .foregroundColor(.orangeRed)
                            Stepper("", value: Binding(
                                get: { prog.currentWeight },
                                set: {
                                    prog.currentWeight = $0
                                    try? prog.modelContext?.save()
                                }
                            ), in: 45...1000, step: 5)
                            .labelsHidden()
                        }
                    }
                }

                // MARK: - Progression Settings
                Section("Progression") {
                    ForEach(progressions) { prog in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prog.exerciseName)
                                .font(.subheadline)
                            HStack {
                                Text("Increment:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(prog.incrementLbs)) lbs")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Stepper("", value: Binding(
                                    get: { prog.incrementLbs },
                                    set: { prog.incrementLbs = $0; try? prog.modelContext?.save() }
                                ), in: 2.5...20, step: 2.5)
                                .labelsHidden()
                                .scaleEffect(0.8)

                                Spacer()

                                if prog.consecutiveFailures > 0 {
                                    Text("\(prog.consecutiveFailures)/3 fails")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }

                                if prog.deloadCount > 0 {
                                    Text("\(prog.deloadCount) deloads")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            if prog.needsDeload {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Deload recommended!")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Button("Apply Deload") {
                                        viewModel.progressionService.checkAndApplyDeload(for: prog.exerciseName)
                                        loadProgressions()
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                    .tint(.orange)
                                }
                            }
                        }
                    }
                }

                // MARK: - Rest Timer
                Section("Rest Timer") {
                    Toggle("Auto-start timer after set", isOn: .constant(true))
                    HStack {
                        Text("Default rest (non-deadlift)")
                        Spacer()
                        Text("90s")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Deadlift rest")
                        Spacer()
                        Text("180s")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - Body Weight
                Section("Body Weight") {
                    NavigationLink {
                        BodyWeightView()
                    } label: {
                        HStack {
                            Image(systemName: "figure.stand")
                                .foregroundColor(.orangeRed)
                            Text("Track Body Weight")
                        }
                    }
                }

                // MARK: - Units
                Section("Units") {
                    HStack {
                        Text("Weight Unit")
                        Spacer()
                        Text("lbs")
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("ONTHERACK — Built for the 5x5 grind.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceDark)
            .preferredColorScheme(.dark)
            .navigationTitle("Settings")
            .onAppear {
                loadProgressions()
            }
        }
    }

    private func loadProgressions() {
        progressions = viewModel.progressionService.fetchAllProgressions()
    }
}

struct BodyWeightView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var records: [BodyWeightRecord] = []
    @State private var newWeight: String = ""

    var body: some View {
        List {
            Section("Add Entry") {
                HStack {
                    TextField("Weight (lbs)", text: $newWeight)
                        .keyboardType(.decimalPad)
                    Button("Add") {
                        guard let w = Double(newWeight), w > 0 else { return }
                        let record = BodyWeightRecord(weight: w)
                        modelContext.insert(record)
                        try? modelContext.save()
                        newWeight = ""
                        loadRecords()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orangeRed)
                    .disabled(newWeight.isEmpty)
                }
            }

            Section("History") {
                if records.isEmpty {
                    Text("No records yet")
                        .foregroundColor(.secondary)
                }
                ForEach(records) { record in
                    HStack {
                        Text(record.date, style: .date)
                            .font(.subheadline)
                        Spacer()
                        Text("\(record.weight, specifier: "%.1f") lbs")
                            .fontWeight(.semibold)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                    loadRecords()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.surfaceDark)
        .preferredColorScheme(.dark)
        .navigationTitle("Body Weight")
        .onAppear(perform: loadRecords)
    }

    private func loadRecords() {
        let descriptor = FetchDescriptor<BodyWeightRecord>(sortBy: [SortDescriptor<BodyWeightRecord>(\.date, order: .reverse)])
        records = (try? modelContext.fetch(descriptor)) ?? []
    }
}
