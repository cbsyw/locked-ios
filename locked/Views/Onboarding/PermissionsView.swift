//
//  PermissionsView.swift
//  locked
//
//  Screen Time permission request
//

import SwiftUI

struct PermissionsView: View {
    @StateObject private var screenTimeService = ScreenTimeService.shared
    @State private var isRequesting = false
    @State private var showError = false
    
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            VStack(spacing: 15) {
                Text("Screen Time Permission")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Locked needs Screen Time permission to block apps when you're in a focus session")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Why we need it
            VStack(alignment: .leading, spacing: 20) {
                PermissionReasonRow(
                    icon: "app.badge.fill",
                    text: "Block selected apps during focus time"
                )
                
                PermissionReasonRow(
                    icon: "shield.fill",
                    text: "Prevent access until you return to your lock point"
                )
                
                PermissionReasonRow(
                    icon: "lock.fill",
                    text: "System-level enforcement (can't cheat!)"
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 15) {
                if screenTimeService.isAuthorized {
                    // Already authorized
                    Button(action: onNext) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Permission Granted - Continue")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                } else {
                    // Request authorization
                    Button(action: requestPermission) {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Grant Permission")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .disabled(isRequesting)
                    
                    Button(action: onNext) {
                        Text("Skip for Now")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .alert("Permission Denied", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can grant permission later in Settings")
        }
    }
    
    private func requestPermission() {
        isRequesting = true
        
        Task {
            do {
                try await screenTimeService.requestAuthorization()
                
                await MainActor.run {
                    isRequesting = false
                    
                    // Auto-advance after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onNext()
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    showError = true
                }
            }
        }
    }
}

struct PermissionReasonRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

#Preview {
    PermissionsView(onNext: {})
}
