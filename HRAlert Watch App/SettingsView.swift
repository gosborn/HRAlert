//
//  SettingsView.swift
//  HRAlert Watch App
//
//  Created by Greg Osborn on 2/19/26.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var healthManager: HealthManager
    var isCurrentTab: Bool
    
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
            
            Text("Scroll crown to adjust")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .focusable()
        .focused($isFocused)
        .digitalCrownRotation(
            $healthManager.heartRateThreshold,
            from: 80.0,
            through: 180.0,
            by: 5.0, // Steps by 5 BPM per crown click
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            if isCurrentTab {
                isFocused = true
            }
        }
        .onChange(of: isCurrentTab) { _, newValue in
            if newValue {
                isFocused = true
            }
        }
    }
}
