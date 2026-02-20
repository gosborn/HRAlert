//
//  SettingsView.swift
//  HRAlert Watch App
//
//  Created by Greg Osborn on 2/19/26.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var healthManager: HealthManager
    
    // Required to capture the hardware input from the Digital Crown
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Alert Threshold")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(Int(healthManager.heartRateThreshold)) BPM")
                .font(.system(.title, design: .rounded).bold())
                .foregroundColor(.red)
                .focusable()
                .focused($isFocused) // Bind the focus state
                .digitalCrownRotation(
                    $healthManager.heartRateThreshold,
                    from: 80.0,
                    through: 180.0,
                    by: 5.0, // Steps by 5 BPM per crown click
                    sensitivity: .low,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
            
            Text("Scroll crown to adjust")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .onAppear {
            // Auto-focus when they swipe to this tab so the crown works immediately
            isFocused = true
        }
    }
}
