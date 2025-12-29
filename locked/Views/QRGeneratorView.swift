//
//  QRGeneratorView.swift
//  locked
//
//  View for generating and displaying QR codes
//

import SwiftUI

struct QRGeneratorView: View {
    
    @State private var lockPointName: String = ""
    @State private var generatedQRImage: UIImage? = nil
    @State private var showQRCode: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Create Lock Point")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Generate a QR code for your lock location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lock Point Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("e.g., Library Desk, Home Office", text: $lockPointName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                }
                .padding(.horizontal, 30)
                
                // Generate Button
                Button(action: generateQRCode) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Generate QR Code")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(lockPointName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(lockPointName.isEmpty)
                .padding(.horizontal, 30)
                
                // QR Code Display
                if showQRCode, let qrImage = generatedQRImage {
                    VStack(spacing: 15) {
                        Text("Your QR Code")
                            .font(.headline)
                        
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Text("Print or save this code")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Action Buttons
                        HStack(spacing: 15) {
                            Button(action: shareQRCode) {
                                Label("Share", systemImage: "square.and.arrow.up")
                                    .font(.subheadline)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: saveQRCode) {
                                Label("Save", systemImage: "square.and.arrow.down")
                                    .font(.subheadline)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Functions
    
    private func generateQRCode() {
        // Generate unique ID for this lock point
        let lockPointID = UUID().uuidString
        
        // Generate QR code
        generatedQRImage = QRCodeService.generateLockPointQR(lockPointID: lockPointID)
        
        // Animate the display
        withAnimation(.spring()) {
            showQRCode = true
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func shareQRCode() {
        guard let image = generatedQRImage else { return }
        
        let activityController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        // Present share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func saveQRCode() {
        guard let image = generatedQRImage else { return }
        
        // Save to photo library
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // TODO: Show success alert
        print("✅ QR Code saved to Photos")
    }
}

// MARK: - Preview

struct QRGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        QRGeneratorView()
    }
}
