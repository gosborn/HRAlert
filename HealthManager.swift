//
//  HealthManager.swift
//  HRAlert
//
//  Created by Greg Osborn on 2/19/26.
//
import WatchKit
import Foundation
import HealthKit
import Observation

@Observable
class HealthManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    // The core interface to Apple Health
    let healthStore = HKHealthStore()
    
    // Tracks whether the user has granted us access
    var isAuthorized = false
    
    // Controls the background session
    var workoutSession: HKWorkoutSession?
    var workoutBuilder: HKLiveWorkoutBuilder?
        
    // Tracks if we are actively reading the pulse
    var isMonitoring = false
    
    // New variables for our UI and logic
    var currentHeartRate: Double = 0.0
    var heartRateThreshold: Double {
        get {
            let savedValue = UserDefaults.standard.double(forKey: "HeartRateThreshold")
            // Return 110.0 as the default if they haven't set a custom one yet
            return savedValue == 0 ? 110.0 : savedValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "HeartRateThreshold")
        }
    }
    var lastAlertTime: Date?

    func requestAuthorization() async {
        // 1. Ensure HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else { return }

        // 2. Define the exact metric we want to read (Heart Rate)
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        // We only need permission to read data, not write/save it
        let typesToRead: Set = [heartRateType]

        do {
            // 3. Trigger the system permission prompt
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            
            // If we reach here, the prompt was dismissed (either approved or denied)
            // HealthKit doesn't tell us if they denied it for privacy reasons,
            // but we can assume we are clear to proceed with setting up the session.
            DispatchQueue.main.async {
                self.isAuthorized = true
            }
        } catch {
            print("Error requesting HealthKit authorization: \(error.localizedDescription)")
        }
    }
    
    func startMonitoring() {
        guard isAuthorized else { return }
        self.isMonitoring = true
        
        #if targetEnvironment(simulator)
        // MARK: - MOCK DATA FOR MAC SIMULATOR
        // Fire a timer every 1 second to generate a fake heartbeat
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isMonitoring else {
                timer.invalidate()
                return
            }
            
            // Generate a random BPM between 90 and 120
            let fakeBPM = Double.random(in: 90...120)
            
            DispatchQueue.main.async {
                self.currentHeartRate = fakeBPM
                self.evaluateHeartRate()
            }
        }
        #else
        // MARK: - REAL HEALTHKIT CODE FOR PHYSICAL WATCH
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mindAndBody
        configuration.locationType = .unknown
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            
            workoutBuilder?.beginCollection(withStart: startDate) { success, error in
                if let error = error {
                    print("Error starting collection: \(error.localizedDescription)")
                }
            }
        } catch {
            print("Failed to start session: \(error.localizedDescription)")
        }
        #endif
    }

    func stopMonitoring() {
        // 1. Instantly update the UI and stop the simulator's mock timer
        self.isMonitoring = false
        
        #if targetEnvironment(simulator)
        // MARK: - MOCK DATA STOP
        print("Simulator: Mock monitoring stopped.")
        
        #else
        // MARK: - REAL HEALTHKIT STOP
        // End the actual workout session and stop the hardware sensors
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            if let error = error {
                print("Error stopping collection: \(error.localizedDescription)")
            } else {
                print("Hardware monitoring stopped.")
            }
        }
        #endif
    }
    
    func evaluateHeartRate() {
        if currentHeartRate >= heartRateThreshold {
            let now = Date()
            
            // Check if we've fired an alert in the last 60 seconds
            if let lastAlert = lastAlertTime, now.timeIntervalSince(lastAlert) < 60 {
                // We are still in the cooldown period, do nothing
                return
            }
            
            print("Threshold exceeded! Current BPM: \(currentHeartRate)")
            WKInterfaceDevice.current().play(.notification)
            
            // Reset the cooldown timer
            lastAlertTime = now
        }
    }
}

// MARK: - Live Data Builder Delegate
extension HealthManager {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            // We only care about Heart Rate data
            guard let quantityType = type as? HKQuantityType,
                  quantityType == HKObjectType.quantityType(forIdentifier: .heartRate) else {
                continue
            }
            
            // Extract the most recent heart rate reading
            if let statistics = workoutBuilder.statistics(for: quantityType),
               let quantity = statistics.mostRecentQuantity() {
                
                // Convert the raw HealthKit data into "Beats Per Minute" (BPM)
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                let value = quantity.doubleValue(for: heartRateUnit)
                
                // Update our UI and check the threshold on the main thread
                DispatchQueue.main.async {
                    self.currentHeartRate = value
                    self.evaluateHeartRate()
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Required protocol stub. We don't need to handle events (like pauses) for this app.
    }
}

// MARK: - Workout Session Delegate
extension HealthManager {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        // We can leave this empty, but it must be here to satisfy the protocol
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}
