
//
//  LockState.swift
//  locked
//
//  Model representing the app's lock state
//

import Foundation

struct LockPoint: Codable, Identifiable {
    let id: String
    let name: String
    let qrCode: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, qrCode: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.qrCode = qrCode
        self.createdAt = createdAt
    }
}

enum LockStatus {
    case unlocked
    case locked(lockPoint: LockPoint, lockedAt: Date)
    
    var isLocked: Bool {
        if case .locked = self {
            return true
        }
        return false
    }
    
    var lockPoint: LockPoint? {
        if case .locked(let lockPoint, _) = self {
            return lockPoint
        }
        return nil
    }
    
    var lockedAt: Date? {
        if case .locked(_, let date) = self {
            return date
        }
        return nil
    }
}
