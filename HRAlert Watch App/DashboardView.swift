//
//  DashboardView.swift
//  HRAlert Watch App
//
//  Created by Greg Osborn on 2/19/26.
//
import SwiftUI

struct DashboardView: View {
    // @Bindable allows us to pass our observable manager down the view tree
    @Bindable var healthManager: HealthManager
    
    var body: some View {
        VStack(spacing: 12) {
            // A circular gauge mapping BPM from a resting 40 up to an agitated 200
            Gauge(value: healthManager.currentHeartRate, in: 40...200) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            } currentValueLabel: {
                Text("\(Int(healthManager.currentHeartRate))")
                    .font(.system(.title, design: .rounded).bold())
            }
            .gaugeStyle(.circular)
            .tint(Gradient(colors: [.blue, .green, .yellow, .red]))
            
            // The main control switch
            Button(healthManager.isMonitoring ? "Stop Session" : "Start Monitoring") {
                if healthManager.isMonitoring {
                    healthManager.stopMonitoring()
                } else {
                    healthManager.startMonitoring()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(healthManager.isMonitoring ? .red : .blue)
            // Ensure they can't start a session if they denied HealthKit permissions
            .disabled(!healthManager.isAuthorized)
        }
    }
}
