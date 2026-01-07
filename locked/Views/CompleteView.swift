//
//  CompleteView.swift
//  locked
//

import SwiftUI

struct CompleteView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 15) {
                Text("You're All Set!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Ready to start your first focus session")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: finishOnboarding) {
                HStack {
                    Text("Start Focusing")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
    
    private func finishOnboarding() {
        if let lockPoint = onboardingManager.firstLockPoint {
            LockService.shared.saveLockPoint(lockPoint)
        }
        onboardingManager.completeOnboarding()
    }
}

#Preview {
    CompleteView(onboardingManager: OnboardingManager())
}
