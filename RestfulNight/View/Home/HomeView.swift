import SwiftUI
import Charts

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var progress: Double = 0.75 // Example progress (75%)
    @State private var score: Double = 75 // Example score
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Progress Ring
                ProgressRing(progress: progress, value: $score)
                    .padding(.top, 20)
                
                // Picker for Day / Week / Month
                Picker("Time View", selection: $viewModel.timeView) {
                    ForEach(TimeView.allCases, id: \.self) { view in
                        Text(view.rawValue.capitalized).tag(view)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Stats
                VStack(spacing: 4) {
                    Text("😴 Average Sleep: \(String(format: "%.1f", viewModel.averageSleepDuration())) pts")
                        .font(.headline)
                    Text("😱 Nightmares: \(viewModel.nightmareCount)")
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                // Chart using label + score
                Chart(viewModel.filteredSleepData) { data in
                    BarMark(
                        x: .value("Label", data.label),
                        y: .value("Score", data.score)
                    )
                    .foregroundStyle(.blue.gradient)
                    .annotation(position: .top) {
                        Text("\(data.score)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 250)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("RestfulNight")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.filterSleepData()
            viewModel.loadNightmareData()
            
            // Update progress and score
            let averageScore = viewModel.averageSleepDuration()
            score = averageScore
            progress = averageScore / 100 // Assuming the maximum score is 100
        }
    }
}

struct ProgressRing: View {
    var progress: Double // Value between 0 and 1
    @Binding var value: Double // The number displayed in the middle
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 20)
            
            Circle()
                .trim(from: 1 - progress, to: 1) // Reverse the trim to make it counterclockwise
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90)) // Rotate counterclockwise to start from the top
            
            VStack {
                Text("\(Int(value))")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("score")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 150, height: 150) // Adjust size as needed
    }
}


