import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if let viewModel {
                TabView(selection: $selectedTab) {
                    HomeView(viewModel: viewModel)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)

                    WorkoutLaunchView(viewModel: viewModel)
                        .tabItem {
                            Label("Train", systemImage: "dumbbell.fill")
                        }
                        .tag(1)

                    HistoryView(viewModel: viewModel)
                        .tabItem {
                            Label("History", systemImage: "chart.bar.fill")
                        }
                        .tag(2)

                    SettingsView(viewModel: viewModel)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(3)
                }
                .tint(.orangeRed)
            } else {
                ProgressView("Loading...")
                    .task {
                        viewModel = WorkoutViewModel(modelContext: modelContext)
                    }
            }
        }
    }
}

extension Color {
    static let orangeRed = Color(red: 1.0, green: 0.27, blue: 0.0)
    static let surfaceDark = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let cardDark = Color(red: 0.17, green: 0.17, blue: 0.18)
}
