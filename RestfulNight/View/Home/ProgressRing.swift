//
//  ProgressRing.swift
//  RestfulNight
//
//  Created by Nick Shan on 2025-11-09.
//
import SwiftUI

struct ProgressRing: View {
    var progress: Double // Value between 0 and 1
    @Binding var value: Double // The number displayed in the middle
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 20)
            
            Circle()
                .trim(from: 0, to: progress) // Fill clockwise from start
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90)) // Start from 12 o'clock
            
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
