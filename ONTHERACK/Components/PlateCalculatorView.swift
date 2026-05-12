import SwiftUI

struct PlateCalculatorView: View {
    @State private var targetWeight: String = ""
    @State private var barWeight: Double = 45

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Plate Calculator")
                    .font(.title2)
                    .fontWeight(.bold)

                HStack {
                    TextField("Total weight (lbs)", text: $targetWeight)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.black)

                    Picker("Bar", selection: $barWeight) {
                        Text("45 lbs").tag(45.0)
                        Text("35 lbs").tag(35.0)
                        Text("20 kg").tag(44.0)
                    }
                    .pickerStyle(.menu)
                    .tint(.orangeRed)
                }
                .padding(.horizontal)

                if let total = Double(targetWeight), total > barWeight {
                    let perSide = platesPerSide(total: total)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Each Side")
                            .font(.headline)

                        ForEach(perSide, id: \.0) { (plate, count) in
                            HStack {
                                Text("\(Int(plate)) lbs")
                                    .fontWeight(.medium)
                                    .frame(width: 60, alignment: .leading)
                                Text("x\(count)")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(plate * Double(count))) lbs total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.cardDark)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Divider()
                            .background(Color.gray.opacity(0.3))

                        HStack {
                            Text("Per Side Total:")
                                .font(.subheadline)
                            Spacer()
                            Text("\((total - barWeight) / 2, specifier: "%.0f") lbs")
                                .fontWeight(.bold)
                                .foregroundColor(.orangeRed)
                        }

                        HStack {
                            Text("Bar Weight:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(barWeight)) lbs")
                                .fontWeight(.bold)
                        }

                        HStack {
                            Text("Grand Total:")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(total)) lbs")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orangeRed)
                        }
                    }
                    .padding()
                    .background(Color.surfaceDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                } else {
                    ContentUnavailableView(
                        "Enter a weight",
                        systemImage: "divide.square",
                        description: Text("Enter a weight greater than the bar weight to see plate configuration.")
                    )
                }

                Spacer()
            }
            .padding(.top)
            .background(Color.surfaceDark)
            .preferredColorScheme(.dark)
        }
    }

    private func platesPerSide(total: Double) -> [(Double, Int)] {
        ProgressionService.platesForWeight(total, barWeight: barWeight)
    }
}
