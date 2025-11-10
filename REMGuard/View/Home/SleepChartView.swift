//
//  SleepChartView.swift
//  RestfulNight
//
//  Created by Josh on 08/11/2025.
//

import SwiftUI
import Charts
import FirebaseFirestore

struct SleepChartView: View {
    @State private var selectedTab: String = "Weekly"
    @State private var weeklyScores: [SleepScoreData] = []
    @State private var monthlyScores: [SleepScoreData] = []
    @State private var averageSleep: Double = 0
    @State private var nightmareCount: Int = 0
    
    private let db = Firestore.firestore()
    private let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownDeviceID"
    
    var body: some View {
        VStack(spacing: 16) {
            // Picker for weekly vs monthly
            Picker("Period", selection: $selectedTab) {
                Text("Weekly").tag("Weekly")
                Text("Monthly").tag("Monthly")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedTab) {
                loadSleepData()
                loadNightmareData()
            }

            
            
            // Stats summary
            VStack(spacing: 4) {
                Text("😴 Average Sleep Score: \(String(format: "%.1f", averageSleep))")
                    .font(.headline)
                Text("😱 Nightmares: \(nightmareCount)")
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 10)
            
            // Chart
            if selectedTab == "Weekly" {
                Chart(weeklyScores) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Sleep Score", item.score)
                    )
                    .foregroundStyle(.blue.gradient)
                    .annotation(position: .top) {
                        Text("\(item.score)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 250)
                .padding(.horizontal)
            } else {
                Chart(monthlyScores) { item in
                    BarMark(
                        x: .value("Month", item.label),
                        y: .value("Sleep Score", item.score)
                    )
                    .foregroundStyle(.teal.gradient)
                    .annotation(position: .top) {
                        Text("\(item.score)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 250)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("Sleep Insights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSleepData()
            loadNightmareData()
        }
    }
    
    // MARK: - Data Loaders
    
    /// Loads mock sleep data (replace with Firestore later if desired)
    private func loadSleepData() {
        if selectedTab == "Weekly" {
            weeklyScores = [
                SleepScoreData(label: "Mon", score: 75),
                SleepScoreData(label: "Tue", score: 80),
                SleepScoreData(label: "Wed", score: 70),
                SleepScoreData(label: "Thu", score: 85),
                SleepScoreData(label: "Fri", score: 78),
                SleepScoreData(label: "Sat", score: 90),
                SleepScoreData(label: "Sun", score: 65)
            ]
            averageSleep = weeklyScores.map { Double($0.score) }.reduce(0, +) / Double(weeklyScores.count)
        } else {
            monthlyScores = [
                SleepScoreData(label: "Jan", score: 72),
                SleepScoreData(label: "Feb", score: 76),
                SleepScoreData(label: "Mar", score: 80),
                SleepScoreData(label: "Apr", score: 74),
                SleepScoreData(label: "May", score: 82),
                SleepScoreData(label: "Jun", score: 78),
                SleepScoreData(label: "Jul", score: 85),
                SleepScoreData(label: "Aug", score: 70),
                SleepScoreData(label: "Sep", score: 90),
                SleepScoreData(label: "Oct", score: 75),
                SleepScoreData(label: "Nov", score: 88),
                SleepScoreData(label: "Dec", score: 79)
            ]
            averageSleep = monthlyScores.map { Double($0.score) }.reduce(0, +) / Double(monthlyScores.count)
        }
    }
    
    /// Loads nightmare data from Firestore for the selected period
    private func loadNightmareData() {
        db.collection("nightmares")
            .whereField("deviceID", isEqualTo: deviceID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading nightmare data: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                let nightmares = documents.compactMap { doc -> (Date, Bool)? in
                    let data = doc.data()
                    guard let timestamp = data["timestamp"] as? Timestamp,
                          let hadNightmare = data["hadNightmare"] as? Bool else { return nil }
                    return (timestamp.dateValue(), hadNightmare)
                }
                
                let calendar = Calendar.current
                let now = Date()
                
                if selectedTab == "Weekly" {
                    if let week = calendar.dateInterval(of: .weekOfYear, for: now) {
                        let thisWeekNightmares = nightmares.filter { date, hadNightmare in
                            hadNightmare && date >= week.start && date < week.end
                        }
                        nightmareCount = thisWeekNightmares.count
                    }
                } else {
                    if let month = calendar.dateInterval(of: .month, for: now) {
                        let thisMonthNightmares = nightmares.filter { date, hadNightmare in
                            hadNightmare && date >= month.start && date < month.end
                        }
                        nightmareCount = thisMonthNightmares.count
                    }
                }
            }
    }
}

// MARK: - Model
struct SleepScoreData: Identifiable {
    let id = UUID()
    let label: String
    let score: Int
}
