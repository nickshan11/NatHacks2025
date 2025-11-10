//
//  DataView.swift
//  RestfulNight
//
//  Created by Nick Shan on 2025-11-09.
//
import SwiftUI
import Charts

struct SleepStage: Identifiable, Equatable { // Conformed to Equatable
    let id = UUID()
    let stage: String
    let startTime: Date
    let endTime: Date
    let color: Color

    static func == (lhs: SleepStage, rhs: SleepStage) -> Bool {
        return lhs.id == rhs.id
    }
}

struct DataView: View {
    @State private var sleepData: [SleepStage] = [
        SleepStage(stage: "Awake", startTime: Date().addingTimeInterval(-3600 * 5), endTime: Date().addingTimeInterval(-3600 * 4), color: .red),
        SleepStage(stage: "REM", startTime: Date().addingTimeInterval(-3600 * 4), endTime: Date().addingTimeInterval(-3600 * 3.5), color: .blue),
        SleepStage(stage: "Core", startTime: Date().addingTimeInterval(-3600 * 3.5), endTime: Date().addingTimeInterval(-3600 * 2.5), color: .green),
        SleepStage(stage: "Deep", startTime: Date().addingTimeInterval(-3600 * 2.5), endTime: Date().addingTimeInterval(-3600 * 1.5), color: .purple)
    ]

    var body: some View {
        VStack {
            Text("Sleep Stages")
                .font(.title)
                .padding()

            Chart(sleepData) { data in
                BarMark(
                    xStart: .value("Start Time", data.startTime),
                    xEnd: .value("End Time", data.endTime),
                    y: .value("Stage", data.stage)
                )
                .foregroundStyle(data.color)
                .annotation(position: .overlay) {
                    Text(data.stage)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour)) {
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 300)
            .padding()
            .animation(.easeInOut(duration: 1.0), value: sleepData) // Added transition effect

            Spacer()
        }
        .padding()
    }
}

#Preview {
    DataView()
}

