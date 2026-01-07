//
//  OnboardingStep.swift
//  locked
//
//  Onboarding flow management
//

import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case permissions = 1
    case createOrScanQR = 2
    case selectApps = 3
    case complete = 4
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Locked"
        case .permissions:
            return "Screen Time Permission"
        case .createOrScanQR:
            return "Create Your First Lock Point"
        case .selectApps:
            return "Choose Apps to Block"
        case .complete:
            return "You're All Set!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Stay focused by locking your phone to physical locations using QR codes."
        case .permissions:
            return "We need Screen Time permission to block distracting apps when you're locked."
        case .createOrScanQR:
            return "Generate a QR code for your focus location or scan an existing one."
        case .selectApps:
            return "Select which apps and websites should be blocked during focus sessions."
        case .complete:
            return "You're ready to start your first focus session!"
        }
    }
    
    var icon: String {
        switch self {
        case .welcome:
            return "lock.shield.fill"
        case .permissions:
            return "hand.raised.fill"
        case .createOrScanQR:
            return "qrcode"
        case .selectApps:
            return "app.badge"
        case .complete:
            return "checkmark.circle.fill"
        }
    }
    
    var nextButtonTitle: String {
        switch self {
        case .welcome:
            return "Get Started"
        case .permissions:
            return "Grant Permission"
        case .createOrScanQR:
            return "Continue"
        case .selectApps:
            return "Finish Setup"
        case .complete:
            return "Start Focusing"
        }
    }
}

class OnboardingManager: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var firstLockPoint: LockPoint?
    @Published var selectedApps: Set<String> = []
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        firstLockPoint = nil
        selectedApps = []
    }
}
