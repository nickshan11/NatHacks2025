import SwiftUI
import Charts
import Firebase

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var progress: Double = 0.75 // Example progress (75%)
    @State private var score: Double = 75 // Example score

    var body: some View {
        NavigationView {
            ScrollView {
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
                
                // Chart using label + score (shown for Day and Week)
                if viewModel.timeView != .month {
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
                }
                
                // Show Monthly Calendar View when Month is selected
                if viewModel.timeView == .month {
                    MonthlyView()
                }
                
                Spacer()
                }
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

//struct ProgressRing: View {
//    var progress: Double // Value between 0 and 1
//    @Binding var value: Double // The number displayed in the middle
//    
//    var body: some View {
//        ZStack {
//            Circle()
//                .stroke(Color.gray.opacity(0.3), lineWidth: 20)
//            
//            Circle()
//                .trim(from: 1 - progress, to: 1) // Reverse the trim to make it counterclockwise
//                .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
//                .rotationEffect(.degrees(-90)) // Rotate counterclockwise to start from the top
//            
//            VStack {
//                Text("\(Int(value))")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                Text("score")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
//        }
//        .frame(width: 150, height: 150) // Adjust size as needed
//    }
//}

struct MonthlyView: View {
    @State private var sleepScores: [String: Double] = [:] // Date as key, sleep score as value
    private let deviceID = "exampleDeviceID" // Replace with actual device ID

    var body: some View {
        VStack {
            Text("Monthly Sleep Scores")
                .font(.title)
                .padding()

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 7), spacing: 20) {
                    ForEach(1...30, id: \ .self) { day in
                        let dateKey = "2025-11-\(String(format: "%02d", day))"
                        let score = sleepScores[dateKey] ?? 0.0

                        ProgressRingView(progress: score / 100.0)
                            .frame(width: 40, height: 40)
                            .overlay(Text("\(day)").font(.caption2))
                            .padding(4)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical)
        }
        .onAppear {
            fetchSleepScores()
        }
    }

    private func fetchSleepScores() {
        let db = Firestore.firestore()
        db.collection(deviceID).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching sleep scores: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            var scores: [String: Double] = [:]
            for document in documents {
                if let date = document.documentID as? String, let score = document["score"] as? Double {
                    scores[date] = score
                }
            }

            if scores.isEmpty {
                // Generate mock data for visualization
                for day in 1...30 {
                    let dateKey = "2025-11-\(String(format: "%02d", day))"
                    scores[dateKey] = Double.random(in: 50...100)
                }
            }

            DispatchQueue.main.async {
                self.sleepScores = scores
            }
        }
    }
}

struct ProgressRingView: View {
    var progress: Double // Value between 0.0 and 1.0

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 5)
                .opacity(0.3)
                .foregroundColor(.blue)

            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut, value: progress)
        }
    }
}

#Preview {
    HomeView()
}


