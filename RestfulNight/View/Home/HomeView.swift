import SwiftUI
import Charts

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
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
                    Text("😴 Average Sleep: \(String(format: "%.1f", viewModel.averageSleepDuration())) hrs")
                        .font(.headline)
                    Text("😱 Nightmares: \(viewModel.nightmareCount)")
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                // Chart
                Chart(viewModel.filteredSleepData) { data in
                    BarMark(
                        x: .value("Date", data.date, unit: .day),
                        y: .value("Sleep Hours", data.sleepDuration)
                    )
                    .foregroundStyle(.blue.gradient)
                    .annotation(position: .top) {
                        Text(String(format: "%.1f", data.sleepDuration))
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
        }
    }
}
