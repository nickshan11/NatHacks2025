//
//  NightmaresView.swift
//  RestfulNight
//
//  Created by Josh Effero on 08/11/25.
//

import SwiftUI
import FirebaseFirestore

struct NightmaresView: View {
    @State private var nightmareCounts: [String: Int] = [:] // YYYY-MM-DD -> count
    @State private var selectedDate: String? = nil
    @State private var showingLogSheet = false
    @State private var newDescription: String = ""
    @State private var newIntensity: Double = 5
    @State private var vibrationStrength: Int = 3 // 1-5 scale
    @State private var statusMessage: String? = nil

    private let calendar = Calendar(identifier: .gregorian)
    private let monthFormatter: DateFormatter = {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM"; return df
    }()
    private let dayFormatter: DateFormatter = {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; return df
    }()

    private var currentMonthKey: String { monthFormatter.string(from: Date()) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Nightmare Calendar")
                        .font(.title2).bold()
                        .padding(.horizontal)

                    MonthGridView(monthKey: currentMonthKey,
                                   counts: nightmareCounts,
                                   onSelect: { dateKey in
                                        selectedDate = dateKey
                                        showingLogSheet = true
                                   })
                        .padding(.horizontal)

                    // Vibration Strength Slider
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Vibration Strength")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Button(action: {
                                    vibrationStrength = level
                                }) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(vibrationStrength == level ? Color.blue : Color.gray.opacity(0.2))
                                            .frame(height: 50)
                                        
                                        Text("\(level)")
                                            .font(.headline)
                                            .foregroundColor(vibrationStrength == level ? .white : .primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("Light")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Strong")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)

                    if let statusMessage = statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Nightmares")
            .onAppear { loadNightmareCounts() }
            .sheet(isPresented: $showingLogSheet) {
                logSheet
            }
        }
    }

    // Mock load; replace with Firestore fetching later
    private func loadNightmareCounts() {
        nightmareCounts.removeAll()
        // Determine days in current month
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
            let key = dayFormatter.string(from: date)
            // Mock counts: more nightmares near mid-month
            nightmareCounts[key] = Int.random(in: 0...3) + (day % 10 == 0 ? Int.random(in: 0...2) : 0)
        }
    }

    private var logSheet: some View {
        VStack(spacing: 20) {
            Text(selectedDate ?? "")
                .font(.headline)
            TextField("Describe nightmare", text: $newDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            VStack(alignment: .leading) {
                Text("Intensity: \(Int(newIntensity)) / 10")
                Slider(value: $newIntensity, in: 1...10, step: 1)
            }
            
            Button {
                saveNightmareEntry()
            } label: {
                Text("Add Entry")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            if let statusMessage = statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }

    private func saveNightmareEntry() {
        guard let dateKey = selectedDate else { return }
        let current = nightmareCounts[dateKey] ?? 0
        nightmareCounts[dateKey] = current + 1
        statusMessage = "Nightmare logged (mock). Vibration: \(vibrationStrength)/5"
        newDescription = ""
        newIntensity = 5
        vibrationStrength = 3
    }
}

// MARK: - Calendar Grid Component
private struct MonthGridView: View {
    let monthKey: String // YYYY-MM
    let counts: [String: Int]
    let onSelect: (String) -> Void

    private let calendar = Calendar(identifier: .gregorian)
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"; return df
    }()

    var body: some View {
        let monthStart = dateFormatter.date(from: monthKey + "-01") ?? Date()
        let daysRange = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
            ForEach(Array(daysRange), id: \ .self) { day in
                let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
                let key = dateFormatter.string(from: date)
                let count = counts[key] ?? 0
                DayCell(day: day, count: count) {
                    onSelect(key)
                }
            }
        }
    }
}

private struct DayCell: View {
    let day: Int
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\(day)")
                    .font(.caption)
                    .foregroundColor(.primary)
                ZStack {
                    Circle()
                        .stroke(count == 0 ? Color.green : Color.gray.opacity(0.2), lineWidth: 4)
                        .frame(width: 34, height: 34)
                    Circle()
                        .trim(from: 0, to: min(1, Double(count) / 4.0))
                        .stroke(color(for: count), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 34, height: 34)
                        .animation(.easeInOut, value: count)
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(color(for: count))
                    } else {
                        // Highlight zero count explicitly in green
                        Text("0")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(minHeight: 60)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: return .gray.opacity(0.4)
        case 1: return .blue
        case 2...3: return .orange
        default: return .red
        }
    }
}


#Preview {
    NightmaresView()
}
