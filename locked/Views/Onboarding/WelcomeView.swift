//
//  WelcomeView.swift
//  locked
//
//  Welcome screen
//

import SwiftUI

struct WelcomeView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 15) {
                Text("Welcome to Locked")
                    .font(.system(size: 34, weight: .bold))
                
                Text("Stay focused by locking your phone to physical locations using QR codes")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Features
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "qrcode.viewfinder",
                    title: "Physical Lock Points",
                    description: "Create QR codes for your focus locations"
                )
                
                FeatureRow(
                    icon: "app.badge.fill",
                    title: "Block Distractions",
                    description: "Real app blocking with Screen Time API"
                )
                
                FeatureRow(
                    icon: "timer",
                    title: "Track Your Focus",
                    description: "See how long you stay locked each day"
                )
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Continue Button
            Button(action: onNext) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView(onNext: {})
}
