//
//  HomeView.swift
//  locked
//
//  Main home screen showing lock status
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var lockService = LockService.shared
    @State private var showScanner = false
    @State private var showCreateLockPoint = false
    @State private var scannerMode: ScannerMode = .lock
    @State private var showUnlockError = false
    
    enum ScannerMode {
        case lock
        case unlock
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: lockService.lockStatus.isLocked ?
                        [Color.red.opacity(0.3), Color.orange.opacity(0.2)] :
                        [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Status Card
                        statusCard
                        
                        // Lock Duration (if locked)
                        if lockService.lockStatus.isLocked {
                            lockDurationCard
                        }
                        
                        // Action Buttons
                        actionButtons
                        
                        // Quick Actions
                        quickActionsSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Locked")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showScanner) {
                scannerSheet
            }
            .sheet(isPresented: $showCreateLockPoint) {
                QRGeneratorView()
            }
            .alert("Wrong QR Code", isPresented: $showUnlockError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This QR code doesn't match your current lock point. Please scan the correct code to unlock.")
            }
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(lockService.lockStatus.isLocked ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: lockService.lockStatus.isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 50))
                    .foregroundColor(lockService.lockStatus.isLocked ? .red : .green)
            }
            
            // Status Text
            Text(lockService.lockStatus.isLocked ? "You're Locked" : "You're Unlocked")
                .font(.title)
                .fontWeight(.bold)
            
            // Lock Point Name
            if let lockPoint = lockService.lockStatus.lockPoint {
                Text("at \(lockPoint.name)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Description
            Text(lockService.lockStatus.isLocked ?
                 "Stay focused! Return to your lock point to unlock." :
                 "Create a lock point or scan a QR code to lock your phone.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(30)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Lock Duration Card
    
    private var lockDurationCard: some View {
        VStack(spacing: 10) {
            Text("Locked for")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let duration = lockService.getLockedDurationFormatted() {
                Text(duration)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Text("Keep going! 💪")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 15) {
            if lockService.lockStatus.isLocked {
                // Unlock Button
                Button(action: {
                    scannerMode = .unlock
                    showScanner = true
                }) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text("Unlock")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                
                // Force Unlock (for testing)
                Button(action: {
                    lockService.forceUnlock()
                }) {
                    Text("Force Unlock (Testing)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else {
                // Lock Button
                Button(action: {
                    scannerMode = .lock
                    showScanner = true
                }) {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Lock Now")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 10) {
                quickActionButton(
                    icon: "qrcode",
                    title: "Create Lock Point",
                    subtitle: "Generate a new QR code",
                    color: .purple
                ) {
                    showCreateLockPoint = true
                }
                
                quickActionButton(
                    icon: "list.bullet",
                    title: "My Lock Points",
                    subtitle: "View saved locations",
                    color: .orange
                ) {
                    // TODO: Navigate to lock points list
                    print("📋 Show lock points list")
                }
            }
        }
    }
    
    private func quickActionButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Scanner Sheet
    
    private var scannerSheet: some View {
        QRScannerView { scannedCode in
            handleScannedCode(scannedCode)
        }
    }
    
    private func handleScannedCode(_ code: String) {
        switch scannerMode {
        case .lock:
            handleLockScan(code)
        case .unlock:
            handleUnlockScan(code)
        }
    }
    
    private func handleLockScan(_ code: String) {
        // Check if this lock point exists
        if let existingLockPoint = lockService.getLockPoint(by: code) {
            lockService.lock(with: existingLockPoint)
        } else {
            // Create new lock point from scanned code
            let newLockPoint = LockPoint(
                name: "Lock Point \(lockService.lockPoints.count + 1)",
                qrCode: code
            )
            lockService.saveLockPoint(newLockPoint)
            lockService.lock(with: newLockPoint)
        }
        
        showScanner = false
    }
    
    private func handleUnlockScan(_ code: String) {
        let success = lockService.unlock(with: code)
        showScanner = false
        
        if !success {
            showUnlockError = true
        }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
