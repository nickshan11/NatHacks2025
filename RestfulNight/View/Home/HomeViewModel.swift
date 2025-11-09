import Combine
import SwiftUI
import FirebaseFirestore

enum TimeView: String, CaseIterable {
    case day, week, month
}

class HomeViewModel: ObservableObject {
    @Published var sleepData: [SleepScoreData] = []
    @Published var filteredSleepData: [SleepScoreData] = []
    @Published var timeView: TimeView = .week {
        didSet { filterSleepData(); loadNightmareData() }
    }
    
    @Published var nightmareCount: Int = 0
    
    private let db = Firestore.firestore()
    private let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownDeviceID"
    
    init() {
        generateSampleSleepData()
        filterSleepData()
        loadNightmareData()
    }
    
    // Sample sleep data
    private func generateSampleSleepData() {
        let calendar = Calendar.current
        let now = Date()
        sleepData = (0..<7).map { i in
            SleepScoreData(
                date: calendar.date(byAdding: .day, value: -i, to: now)!,
                sleepDuration: Double.random(in: 6.0...9.0)
            )
        }
    }
    
    // Filter according to TimeView
    func filterSleepData() {
        let calendar = Calendar.current
        let now = Date()
        switch timeView {
        case .day:
            filteredSleepData = sleepData.filter { calendar.isDate($0.date, inSameDayAs: now) }
        case .week:
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                filteredSleepData = sleepData.filter { $0.date >= weekAgo && $0.date <= now }
            }
        case .month:
            if let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) {
                filteredSleepData = sleepData.filter { $0.date >= monthAgo && $0.date <= now }
            }
        }
    }
    
    // Average sleep
    func averageSleepDuration() -> Double {
        guard !filteredSleepData.isEmpty else { return 0 }
        let total = filteredSleepData.map { $0.sleepDuration }.reduce(0, +)
        return total / Double(filteredSleepData.count)
    }
    
    // Load nightmare count from Firestore
    func loadNightmareData() {
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
                
                switch self.timeView {
                case .day:
                    self.nightmareCount = nightmares.filter {
                        $0.1 && calendar.isDate($0.0, inSameDayAs: now)
                    }.count
                case .week:
                    if let week = calendar.dateInterval(of: .weekOfYear, for: now) {
                        self.nightmareCount = nightmares.filter {
                            $0.1 && $0.0 >= week.start && $0.0 < week.end
                        }.count
                    }
                case .month:
                    if let month = calendar.dateInterval(of: .month, for: now) {
                        self.nightmareCount = nightmares.filter {
                            $0.1 && $0.0 >= month.start && $0.0 < month.end
                        }.count
                    }
                }
            }
    }
}
