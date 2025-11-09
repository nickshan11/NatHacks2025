//
//  HomeViewModel.swift
//  RestfulNight
//
//  Created by Deimante Valunaite on 11/07/2024.
//

import Combine
import SwiftUI

enum TimeView: String, CaseIterable {
    case day, week, month
}

struct SleepData: Identifiable {
    let id = UUID()
    let date: Date
    let sleepDuration: Double
}

class HomeViewModel: ObservableObject {
    @Published var sleepData: [SleepData] = []
    @Published var filteredSleepData: [SleepData] = []
    @Published var timeView: TimeView = .week
    
    init() {
        generateSampleSleepData()
        filterSleepData()
    }
    
    private func generateSampleSleepData() {
        sleepData = [
            SleepData(date: Date().addingTimeInterval(-86400 * 6), sleepDuration: 7.0),
            SleepData(date: Date().addingTimeInterval(-86400 * 5), sleepDuration: 6.5),
            SleepData(date: Date().addingTimeInterval(-86400 * 4), sleepDuration: 8.0),
            SleepData(date: Date().addingTimeInterval(-86400 * 3), sleepDuration: 7.5),
            SleepData(date: Date().addingTimeInterval(-86400 * 2), sleepDuration: 6.0),
            SleepData(date: Date().addingTimeInterval(-86400), sleepDuration: 7.2),
            SleepData(date: Date(), sleepDuration: 8.0)
        ]
    }
    
    func filterSleepData() {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeView {
        case .day:
            filteredSleepData = sleepData.filter {
                calendar.isDate($0.date, inSameDayAs: now)
            }
        case .week:
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                filteredSleepData = sleepData.filter {
                    $0.date >= weekAgo && $0.date <= now
                }
            }
        case .month:
            if let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) {
                filteredSleepData = sleepData.filter {
                    $0.date >= monthAgo && $0.date <= now
                }
            }
        }
    }
}
