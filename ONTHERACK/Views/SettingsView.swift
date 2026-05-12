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

// MARK: - Plan List

struct PlanListView: View {
    @State private var viewModel: WorkoutViewModel
    let onChange: () -> Void
    @State private var templates: [WorkoutTemplate] = []
    @State private var showingAddPlanSheet = false

    init(viewModel: WorkoutViewModel, onChange: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onChange = onChange
    }

    var body: some View {
        List {
            Section {
                Text("Plans you can pick from when starting a workout. Tap a row to edit its exercises.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Plans") {
                if templates.isEmpty {
                    Text("No plans yet. Tap + to add one.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(templates) { template in
                        NavigationLink {
                            PlanEditorView(viewModel: viewModel, template: template) {
                                refresh()
                            }
                        } label: {
                            HStack {
                                Text(template.name)
                                    .font(.headline)
                                Spacer()
                                Text("\(template.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.surfaceDark)
        .preferredColorScheme(.dark)
        .navigationTitle("Workout Plans")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton().tint(.orangeRed)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddPlanSheet = true } label: {
                    Image(systemName: "plus")
                }
                .tint(.orangeRed)
            }
        }
        .sheet(isPresented: $showingAddPlanSheet) {
            AddPlanSheet { name in
                _ = viewModel.workoutService.createTemplate(name: name)
                refresh()
            }
            .preferredColorScheme(.dark)
        }
        .onAppear { refresh() }
    }

    private func refresh() {
        templates = viewModel.workoutService.fetchTemplates()
        onChange()
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            viewModel.workoutService.deleteTemplate(templates[idx])
        }
        refresh()
    }

    private func move(from: IndexSet, to: Int) {
        var ordered = templates
        ordered.move(fromOffsets: from, toOffset: to)
        for (i, t) in ordered.enumerated() {
            t.sortOrder = i
        }
        viewModel.workoutService.saveTemplateChanges()
        refresh()
    }
}

private struct AddPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    let onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan Name") {
                    TextField("e.g. Push Day", text: $name)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceDark)
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onAdd(trimmed)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(.orangeRed)
                }
            }
        }
    }
}

// MARK: - Plan Editor

struct PlanEditorView: View {
    @State private var viewModel: WorkoutViewModel
    let template: WorkoutTemplate
    let onChange: () -> Void
    @State private var showingAddSheet = false

    init(viewModel: WorkoutViewModel, template: WorkoutTemplate, onChange: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.template = template
        self.onChange = onChange
    }

    var sortedExercises: [TemplateExercise] {
        template.exercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        @Bindable var template = template
        return List {
            Section("Plan Name") {
                TextField("Plan name", text: $template.name)
                    .font(.headline)
                    .onSubmit { save() }
            }

            Section {
                Text("Changes apply to new workouts only. An in-progress workout uses the plan that was active when it started.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Exercises") {
                ForEach(sortedExercises) { exercise in
                    PlanExerciseRow(exercise: exercise) {
                        save()
                    }
                }
                .onDelete { offsets in
                    delete(at: offsets)
                }
                .onMove { from, to in
                    move(from: from, to: to)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.surfaceDark)
        .preferredColorScheme(.dark)
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
                    .tint(.orangeRed)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .tint(.orangeRed)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddExerciseSheet { name in
                addExercise(named: name)
            }
            .preferredColorScheme(.dark)
        }
    }

    private func save() {
        viewModel.workoutService.saveTemplateChanges()
        onChange()
    }

    private func addExercise(named name: String) {
        let nextOrder = (template.exercises.map(\.sortOrder).max() ?? -1) + 1
        let isAccessory = !["Barbell Squat", "Barbell Bench Press", "Barbell Row",
                            "Overhead Press", "Deadlift"].contains(name)
        template.exercises.append(TemplateExercise(
            exerciseName: name,
            targetSets: 5,
            targetReps: 5,
            sortOrder: nextOrder,
            isAccessory: isAccessory
        ))
        save()
    }

    private func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { sortedExercises[$0] }
        for ex in toDelete {
            if let idx = template.exercises.firstIndex(where: { $0.id == ex.id }) {
                template.exercises.remove(at: idx)
            }
        }
        // Re-pack sortOrder so subsequent reorders behave predictably.
        for (i, ex) in template.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }).enumerated() {
            ex.sortOrder = i
        }
        save()
    }

    private func move(from: IndexSet, to: Int) {
        var ordered = sortedExercises
        ordered.move(fromOffsets: from, toOffset: to)
        for (i, ex) in ordered.enumerated() {
            ex.sortOrder = i
        }
        // Trigger SwiftUI to pick up the reorder.
        template.exercises = ordered
        save()
    }
}

private struct PlanExerciseRow: View {
    @Bindable var exercise: TemplateExercise
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Exercise name", text: $exercise.exerciseName)
                .font(.headline)
                .onSubmit(onChange)

            HStack {
                Text("Sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Stepper("\(exercise.targetSets)", value: Binding(
                    get: { exercise.targetSets },
                    set: { exercise.targetSets = $0; onChange() }
                ), in: 1...10)
                .labelsHidden()
                Text("\(exercise.targetSets)")
                    .font(.caption)
                    .frame(width: 24, alignment: .leading)

                Spacer()

                Text("Reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Stepper("\(exercise.targetReps)", value: Binding(
                    get: { exercise.targetReps },
                    set: { exercise.targetReps = $0; onChange() }
                ), in: 1...20)
                .labelsHidden()
                Text("\(exercise.targetReps)")
                    .font(.caption)
                    .frame(width: 24, alignment: .leading)
            }

            if exercise.isAccessory {
                Text("Accessory")
                    .font(.caption2)
                    .foregroundColor(.orangeRed)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var picked: String = "Custom"
    let onAdd: (String) -> Void

    let suggestions = ["Barbell Squat", "Barbell Bench Press", "Barbell Row",
                       "Overhead Press", "Deadlift", "Pull-up", "Dip",
                       "Barbell Curl", "Tricep Extension", "Custom"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Pick a Common Lift") {
                    Picker("Exercise", selection: $picked) {
                        ForEach(suggestions, id: \.self) { Text($0).tag($0) }
                    }
                }

                if picked == "Custom" {
                    Section("Custom Name") {
                        TextField("e.g. Front Squat", text: $name)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceDark)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let final = picked == "Custom" ? name.trimmingCharacters(in: .whitespaces) : picked
                        guard !final.isEmpty else { return }
                        onAdd(final)
                        dismiss()
                    }
                    .disabled(picked == "Custom" && name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(.orangeRed)
                }
            }
        }
    }
}
