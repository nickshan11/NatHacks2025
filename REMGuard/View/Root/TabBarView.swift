//
//  TabBarView.swift
//  RestfulNight
//
//  Created by Deimante Valunaite on 07/07/2024.
//

import SwiftUI

struct TabBarView: View {
    @State private var selectedTab = 0
   
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { 
                    Image(systemName: "house")
                    Text("Home")
                }
                .onAppear { selectedTab = 0 }
                .tag(0)
            
            DataView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Data")
                }
                .onAppear { selectedTab = 1 }
                .tag(1)
            
            SleepSettingsView()
                .tabItem {
                    Image(systemName: "moon")
                    Text("Sleep")
                }
                .onAppear { selectedTab = 2 }
                .tag(2)
            
            NightmaresView()
                .tabItem {
                    Image(systemName: "exclamationmark.triangle")
                    Text("Nightmares")
                }
                .onAppear { selectedTab = 3 }
                .tag(3)
            
//            SettingsView()
//                .tabItem {  
//                    Image(systemName: "gearshape")
//                    Text("Settings")
//                }
//                .onAppear { selectedTab = 4 }
//                .tag(4)
        }
    }
}

#Preview {
    TabBarView()
}
