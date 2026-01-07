//
//  ScreenTimeService.swift
//  locked
//
//  Screen Time API integration for app blocking
//

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

class ScreenTimeService: ObservableObject {
    
    static let shared = ScreenTimeService()
    
    @Published var isAuthorized = false
    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    
    private init() {
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
            print("✅ Screen Time already authorized")
        default:
            isAuthorized = false
        }
    }
    
    func requestAuthorization() async throws {
        do {
            try await center.requestAuthorization(for: .individual)
            await MainActor.run {
                isAuthorized = true
                print("✅ Screen Time authorized")
            }
        } catch {
            await MainActor.run {
                isAuthorized = false
            }
            print("❌ Screen Time authorization failed: \(error)")
            throw error
        }
    }
    
    // MARK: - App Blocking
    
    func blockApps(_ selection: FamilyActivitySelection) {
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
        
        print("🔒 Blocked \(selection.applicationTokens.count) apps")
    }
    
    func unblockAll() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        print("🔓 Unblocked all apps")
    }
    
    // MARK: - Store Selection for Later Use
    
    private var savedSelection: FamilyActivitySelection?
    
    func saveSelection(_ selection: FamilyActivitySelection) {
        savedSelection = selection
        
        // Save tokens to UserDefaults for persistence
        // Note: Tokens are opaque and can't be directly serialized
        // But we can save the count for reference
        UserDefaults.standard.set(selection.applicationTokens.count, forKey: "blockedAppsCount")
        
        print("💾 Saved selection: \(selection.applicationTokens.count) apps")
    }
    
    func getSavedSelection() -> FamilyActivitySelection? {
        return savedSelection
    }
    
    func applyBlock() {
        guard let selection = savedSelection else {
            print("⚠️ No saved selection to block")
            return
        }
        blockApps(selection)
    }
}
