//
//  REMGuardApp.swift
//
//  Created by Nick Shan on 08/11/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        addDeviceIDToFirestore()
        return true
    }

    private func addDeviceIDToFirestore() {
        let db = Firestore.firestore()
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "UnknownDeviceID"
        let deviceData: [String: Any] = [
            "deviceID": deviceID,
        ]

        db.collection("devices").document(deviceID).setData(deviceData) { error in
            if let error = error {
                print("Error adding device ID to Firestore: \(error.localizedDescription)")
            } else {
                print("Device ID successfully added to Firestore.")
            }
        }
    }
}

@main
struct RestfulNightApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            TabBarView()
        }
    }
}
