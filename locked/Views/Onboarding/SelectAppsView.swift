//
//  SelectAppsView.swift
//  locked
//
//  Real app selection using FamilyActivityPicker
//

import SwiftUI
import FamilyControls

struct SelectAppsView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    let onNext: () -> Void
    
    @State private var selection = FamilyActivitySelection()
    @State private var isPresented = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 15) {
                Image(systemName: "app.badge")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Choose Apps to Block")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select which apps should be blocked during focus sessions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Selection Display
            if selection.applicationTokens.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No apps selected yet")
                        .foregroundColor(.secondary)
                    
                    Text("Tap the button below to choose apps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("\(selection.applicationTokens.count) app\(selection.applicationTokens.count == 1 ? "" : "s") selected")
                        .font(.headline)
                    
                    if selection.categoryTokens.count > 0 {
                        Text("+ \(selection.categoryTokens.count) categor\(selection.categoryTokens.count == 1 ? "y" : "ies")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if selection.webDomainTokens.count > 0 {
                        Text("+ \(selection.webDomainTokens.count) website\(selection.webDomainTokens.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Select Apps Button
            Button(action: { isPresented = true }) {
                HStack {
                    Image(systemName: selection.applicationTokens.isEmpty ? "plus.app" : "pencil")
                    Text(selection.applicationTokens.isEmpty ? "Select Apps" : "Change Selection")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Continue Button
            VStack(spacing: 10) {
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 30)
                
                if selection.applicationTokens.isEmpty {
                    Text("You can add apps later in settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 40)
        }
        .familyActivityPicker(
            isPresented: $isPresented,
            selection: $selection
        )
    }
    
    private func saveAndContinue() {
        // Save selection to ScreenTimeService
        ScreenTimeService.shared.saveSelection(selection)
        
        // Continue to next step
        onNext()
    }
}

#Preview {
    SelectAppsView(
        onboardingManager: OnboardingManager(),
        onNext: {}
    )
}
