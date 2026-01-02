
//
//  LockService.swift
//  locked
//
//  Service for managing lock state and persistence
//

import Foundation
import Combine

class LockService: ObservableObject {
    
    static let shared = LockService()
    
    @Published private(set) var lockStatus: LockStatus = .unlocked
    @Published private(set) var lockPoints: [LockPoint] = []
    
    private let lockStatusKey = "lockStatus"
    private let lockPointsKey = "lockPoints"
    private let lockedAtKey = "lockedAt"
    private let currentLockPointKey = "currentLockPoint"
    
    private init() {
        loadLockStatus()
        loadLockPoints()
    }
    
    // MARK: - Lock/Unlock
    
    func lock(with lockPoint: LockPoint) {
        lockStatus = .locked(lockPoint: lockPoint, lockedAt: Date())
        saveLockStatus()
        
        print("🔒 Locked with: \(lockPoint.name)")
    }
    
    func unlock(with qrCode: String) -> Bool {
        guard case .locked(let lockPoint, _) = lockStatus else {
            print("⚠️ Already unlocked")
            return false
        }
        
        // Verify QR code matches the lock point
        if lockPoint.qrCode == qrCode {
            lockStatus = .unlocked
            saveLockStatus()
            print("🔓 Unlocked successfully")
            return true
        } else {
            print("❌ Wrong QR code")
            return false
        }
    }
    
    func forceUnlock() {
        lockStatus = .unlocked
        saveLockStatus()
        print("🔓 Force unlocked")
    }
    
    // MARK: - Lock Points Management
    
    func saveLockPoint(_ lockPoint: LockPoint) {
        if let index = lockPoints.firstIndex(where: { $0.id == lockPoint.id }) {
            lockPoints[index] = lockPoint
        } else {
            lockPoints.append(lockPoint)
        }
        saveLockPoints()
        print("💾 Saved lock point: \(lockPoint.name)")
    }
    
    func deleteLockPoint(_ lockPoint: LockPoint) {
        lockPoints.removeAll { $0.id == lockPoint.id }
        saveLockPoints()
        print("🗑️ Deleted lock point: \(lockPoint.name)")
    }
    
    func getLockPoint(by qrCode: String) -> LockPoint? {
        return lockPoints.first { $0.qrCode == qrCode }
    }
    
    // MARK: - Persistence
    
    private func saveLockStatus() {
        UserDefaults.standard.set(lockStatus.isLocked, forKey: lockStatusKey)
        
        if case .locked(let lockPoint, let lockedAt) = lockStatus {
            if let encoded = try? JSONEncoder().encode(lockPoint) {
                UserDefaults.standard.set(encoded, forKey: currentLockPointKey)
            }
            UserDefaults.standard.set(lockedAt, forKey: lockedAtKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentLockPointKey)
            UserDefaults.standard.removeObject(forKey: lockedAtKey)
        }
    }
    
    private func loadLockStatus() {
        let isLocked = UserDefaults.standard.bool(forKey: lockStatusKey)
        
        if isLocked,
           let lockPointData = UserDefaults.standard.data(forKey: currentLockPointKey),
           let lockPoint = try? JSONDecoder().decode(LockPoint.self, from: lockPointData),
           let lockedAt = UserDefaults.standard.object(forKey: lockedAtKey) as? Date {
            lockStatus = .locked(lockPoint: lockPoint, lockedAt: lockedAt)
            print("📱 Restored lock state: \(lockPoint.name)")
        } else {
            lockStatus = .unlocked
        }
    }
    
    private func saveLockPoints() {
        if let encoded = try? JSONEncoder().encode(lockPoints) {
            UserDefaults.standard.set(encoded, forKey: lockPointsKey)
        }
    }
    
    private func loadLockPoints() {
        if let data = UserDefaults.standard.data(forKey: lockPointsKey),
           let decoded = try? JSONDecoder().decode([LockPoint].self, from: data) {
            lockPoints = decoded
            print("📱 Loaded \(decoded.count) lock points")
        }
    }
    
    // MARK: - Helpers
    
    func getLockedDuration() -> TimeInterval? {
        guard let lockedAt = lockStatus.lockedAt else { return nil }
        return Date().timeIntervalSince(lockedAt)
    }
    
    func getLockedDurationFormatted() -> String? {
        guard let duration = getLockedDuration() else { return nil }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}
