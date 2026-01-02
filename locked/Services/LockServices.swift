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
    @Published private(set) var currentSessionDuration: TimeInterval = 0
    @Published private(set) var todayTotalDuration: TimeInterval = 0
    
    private let lockStatusKey = "lockStatus"
    private let lockPointsKey = "lockPoints"
    private let lockedAtKey = "lockedAt"
    private let currentLockPointKey = "currentLockPoint"
    private let todayTotalKey = "todayTotal"
    private let lastDateKey = "lastDate"
    
    private var timer: Timer?
    
    private init() {
        loadLockStatus()
        loadLockPoints()
        loadTodayTotal()
        
        // Start timer if locked
        if lockStatus.isLocked {
            startTimer()
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        // Invalidate existing timer
        timer?.invalidate()
        
        // Create new timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if case .locked(_, let lockedAt) = self.lockStatus {
                self.currentSessionDuration = Date().timeIntervalSince(lockedAt)
                self.todayTotalDuration = self.getBaseTodayTotal() + self.currentSessionDuration
            }
        }
        
        // Ensure timer runs even when scrolling
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Lock/Unlock
    
    func lock(with lockPoint: LockPoint) {
        let now = Date()
        lockStatus = .locked(lockPoint: lockPoint, lockedAt: now)
        currentSessionDuration = 0
        saveLockStatus()
        startTimer()
        
        print("🔒 Locked with: \(lockPoint.name)")
    }
    
    func unlock(with qrCode: String) -> Bool {
        guard case .locked(let lockPoint, let lockedAt) = lockStatus else {
            print("⚠️ Already unlocked")
            return false
        }
        
        // Verify QR code matches the lock point
        if lockPoint.qrCode == qrCode {
            // Save the session duration to today's total
            let sessionDuration = Date().timeIntervalSince(lockedAt)
            saveTodayTotal(additional: sessionDuration)
            
            lockStatus = .unlocked
            currentSessionDuration = 0
            saveLockStatus()
            stopTimer()
            
            print("🔓 Unlocked successfully. Session: \(formatDuration(sessionDuration))")
            return true
        } else {
            print("❌ Wrong QR code")
            return false
        }
    }
    
    func forceUnlock() {
        if case .locked(_, let lockedAt) = lockStatus {
            let sessionDuration = Date().timeIntervalSince(lockedAt)
            saveTodayTotal(additional: sessionDuration)
        }
        
        lockStatus = .unlocked
        currentSessionDuration = 0
        saveLockStatus()
        stopTimer()
        
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
    
    // MARK: - Daily Total Management
    
    private func loadTodayTotal() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            
            if today == lastDay {
                // Same day - load existing total
                todayTotalDuration = UserDefaults.standard.double(forKey: todayTotalKey)
            } else {
                // New day - reset
                todayTotalDuration = 0
                UserDefaults.standard.set(0, forKey: todayTotalKey)
            }
        }
        
        // Update last date
        UserDefaults.standard.set(Date(), forKey: lastDateKey)
    }
    
    private func getBaseTodayTotal() -> TimeInterval {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = UserDefaults.standard.object(forKey: lastDateKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            
            if today == lastDay {
                return UserDefaults.standard.double(forKey: todayTotalKey)
            }
        }
        
        return 0
    }
    
    private func saveTodayTotal(additional: TimeInterval) {
        let currentBase = getBaseTodayTotal()
        let newTotal = currentBase + additional
        
        UserDefaults.standard.set(newTotal, forKey: todayTotalKey)
        UserDefaults.standard.set(Date(), forKey: lastDateKey)
        
        todayTotalDuration = newTotal
        
        print("💾 Saved today's total: \(formatDuration(newTotal))")
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
            currentSessionDuration = Date().timeIntervalSince(lockedAt)
            print("📱 Restored lock state: \(lockPoint.name)")
        } else {
            lockStatus = .unlocked
            currentSessionDuration = 0
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
    
    func getLockedDuration() -> TimeInterval {
        return currentSessionDuration
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        return String(format: "%dh %dm %ds", hours, minutes, seconds)
    }
    
    func getTodayTotalFormatted() -> String {
        return formatDuration(todayTotalDuration)
    }
    
    func getCurrentSessionFormatted() -> String {
        return formatDuration(currentSessionDuration)
    }
}
