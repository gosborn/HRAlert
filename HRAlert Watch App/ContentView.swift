//
//  ContentView.swift
//  HRAlert Watch App
//
//  Created by Greg Osborn on 2/19/26.
//

import SwiftUI

struct ContentView: View {
    @State private var healthManager = HealthManager()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if healthManager.isAuthorized {
                // MARK: - The Approved State
                // They granted permission, so show the actual app
                TabView(selection: $selectedTab) {
                    DashboardView(healthManager: healthManager)
                        .tag(0)
                    SettingsView(healthManager: healthManager)
                        .tag(1)
                }
                .tabViewStyle(.verticalPage)
                
            } else {
                // MARK: - The Non-Approved State
                // Show the messaging you liked from Phase 2
                ScrollView {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.text.square")
                            .font(.title)
                            .foregroundColor(.gray)
                        
                        Text("Permission Required")
                            .font(.headline)
                        
                        Text("We need access to your heart rate to provide alerts during stressful moments.")
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Button("Grant Access") {
                            Task {
                                await healthManager.requestAuthorization()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
        }
        .task {
            // Still attempt to show the official Apple prompt automatically on first launch
            if !healthManager.isAuthorized {
                await healthManager.requestAuthorization()
            }
        }
    }
}
