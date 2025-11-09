//
//  NightmaresView.swift
//  RestfulNight
//
//  Created by Josh Effero on 08/11/25.
//

import SwiftUI
import FirebaseFirestore

struct NightmaresView: View {
    @State private var description: String = ""
    @State private var intensity: Double = 5.0
    @State private var message: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Log a Nightmare")
                    .font(.title2)
                    .bold()

                TextField("Describe your nightmare...", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                VStack {
                    Text("Intensity: \(Int(intensity)) / 10")
                    Slider(value: $intensity, in: 1...10, step: 1)
                        .padding(.horizontal)
                }

                Button(action: saveNightmare) {
                    Text("Save Entry")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                if let message = message {
                    Text(message)
                        .foregroundColor(.gray)
                        .padding(.top)
                }

                Spacer()
            }
            .navigationTitle("Nightmares")
        }
    }

    private func saveNightmare() {
        guard !description.isEmpty else {
            message = "Please enter a description."
            return
        }

        let db = Firestore.firestore()
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownDeviceID"
        let data: [String: Any] = [
            "description": description,
            "intensity": intensity,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("devices").document(deviceID)
            .collection("nightmares").addDocument(data: data) { error in
                if let error = error {
                    message = "Error saving: \(error.localizedDescription)"
                } else {
                    message = "Nightmare saved successfully!"
                    description = ""
                    intensity = 5
                }
            }
    }
}

#Preview {
    NightmaresView()
}
