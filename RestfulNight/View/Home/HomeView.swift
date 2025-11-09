//
//  HomeView.swift
//  RestfulNight
//
//  Created by Deimante Valunaite on 08/07/2024.
//

import SwiftUI
import Charts

struct HomeView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var value: Double = 75 // Default sleep score (between 1 and 100)

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                ProgressRing(progress: value / 100, value: $value)
                    .padding(.top, -100) // TODO: CHANGE THIS LATER
                
                HStack {
                    Text("Weekly Sleep Scores")
                        .font(.headline)
                        .bold()
                    Spacer()
                }
                .padding([.top, .horizontal])
                
                // Placeholder for future graph or widget
                Text("No past scores available")
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.bottom)
                
                
                .toolbar {
                    NavigationLink {
                        SleepChartView()
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tint(.primary)
                }
            }
            .navigationTitle("RestfulNight")
            .navigationBarTitleDisplayMode(.large)
            .padding(.horizontal)
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
                .rotationEffect(.degrees(-90)) // Rotate counterclockwise to start from the left
            
            VStack {
                Text("\(Int(value))")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("score")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 200, height: 200)
    }
}

struct SleepScore: Identifiable {
    let id = UUID()
    let day: String
    let score: Int
}

#Preview {
    HomeView()
}
