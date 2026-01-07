//
//  lockedApp.swift
//  locked
//
//  Created by Christian Warren on 12/28/25.
//

import SwiftUI

@main
struct lockedApp: App {
    @StateObject private var onboardingManager = OnboardingManager()
    
    var body: some Scene {
        WindowGroup {
            if onboardingManager.hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingContainerView()
                    .environmentObject(onboardingManager)
            }
        }
    }
}
