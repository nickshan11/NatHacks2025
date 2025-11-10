import SwiftUI
import Charts

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

struct MonthlyView: View {
    @State private var sleepScores: [String: Double] = [:] // Date as key, sleep score as value
    private let deviceID = "exampleDeviceID" // Replace with actual device ID
    private let apiBaseURL = URL(string: "http://localhost:5000/api")! // Update if running on device

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
        // Build month param YYYY-MM for current month
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthParam = formatter.string(from: Date())

        guard var components = URLComponents(url: apiBaseURL.appendingPathComponent("devices/\(deviceID)/sleep-scores"), resolvingAgainstBaseURL: false) else {
            return
        }
        components.queryItems = [URLQueryItem(name: "month", value: monthParam)]
        guard let url = components.url else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("API error: \(error.localizedDescription). Falling back to mock data.")
                DispatchQueue.main.async { self.sleepScores = generateMockScores(forMonth: monthParam) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { self.sleepScores = generateMockScores(forMonth: monthParam) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(SleepScoresResponse.self, from: data)
                var scoresMap: [String: Double] = [:]
                for entry in decoded.scores {
                    scoresMap[entry.date] = Double(entry.score)
                }
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        self.sleepScores = scoresMap
                    }
                }
            } catch {
                print("Decoding error: \(error). Falling back to mock data.")
                DispatchQueue.main.async { self.sleepScores = generateMockScores(forMonth: monthParam) }
            }
        }
        task.resume()
    }

    private func generateMockScores(forMonth month: String) -> [String: Double] {
        // month format: YYYY-MM
        var map: [String: Double] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let monthStart = dateFormatter.date(from: month + "-01") ?? Date()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    // calendar.range returns Range<Int>?; fallback must match that type (use half-open range 1..<31)
    let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        for day in range {
            let dateKey = String(format: "%@-%02d", month, day)
            map[dateKey] = Double(Int.random(in: 50...100))
        }
        return map
    }
}

// MARK: - API Models
private struct SleepScoresResponse: Decodable {
    let success: Bool
    let deviceId: String
    let month: String
    let scores: [ScoreEntry]
}

private struct ScoreEntry: Decodable {
    let date: String
    let score: Int
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
                .rotationEffect(.degrees(-90)) // Start at top
                .animation(.easeInOut, value: progress)
        }
    }
}

#Preview {
    HomeView()
}


