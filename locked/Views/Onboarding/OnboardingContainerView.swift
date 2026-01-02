//
//  OnboardingContainerView.swift
//  locked
//
//  Main onboarding flow container
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var currentStep: OnboardingStep = .welcome
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .welcome:
                WelcomeView(onNext: { currentStep = .permissions })
            case .permissions:
                PermissionsView(onNext: { currentStep = .createOrScanQR })
            case .createOrScanQR:
                CreateOrScanView(
                    onboardingManager: onboardingManager,
                    onNext: { currentStep = .selectApps }
                )
            case .selectApps:
                SelectAppsView(
                    onboardingManager: onboardingManager,
                    onNext: { currentStep = .complete }
                )
            case .complete:
                CompleteView(onboardingManager: onboardingManager)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
        .animation(.easeInOut, value: currentStep)
    }
}

#Preview {
    OnboardingContainerView()
}
