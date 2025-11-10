// RestfulNight/View/Home/ProgressRing.swift (same file kept together here)
import SwiftUI

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
                .rotationEffect(.degrees(-90)) // Rotate counterclockwise to start from the top
            
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
}//
//  ProgressRing.swift
//  RestfulNight
//
//  Created by Nick Shan on 2025-11-09.
//

