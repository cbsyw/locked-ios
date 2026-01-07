//
//  CreateOrScanView.swift
//  locked
//

import SwiftUI

struct CreateOrScanView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    let onNext: () -> Void
    
    @State private var showQRScanner = false
    @State private var lockPointName = ""
    @State private var generatedQRCode: String?
    @State private var generatedQRImage: UIImage?
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                Image(systemName: "qrcode")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("Create Your Lock Point")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Generate a QR code for your focus location")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 60)
            
            Spacer()
            
            if generatedQRImage != nil {
                qrCodeDisplay
            } else {
                createQRSection
            }
            
            Spacer()
            
            if onboardingManager.firstLockPoint != nil {
                Button(action: onNext) {
                    HStack {
                        Text("Continue")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
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
        .sheet(isPresented: $showQRScanner) {
            QRScannerView { scannedCode in
                handleScannedCode(scannedCode)
            }
        }
    }
    
    private var createQRSection: some View {
        VStack(spacing: 15) {
            TextField("Lock Point Name (e.g., Library Desk)", text: $lockPointName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
                .padding(.horizontal, 30)
            
            Button(action: generateQR) {
                Text("Generate QR Code")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(lockPointName.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .disabled(lockPointName.isEmpty)
            .padding(.horizontal, 30)
            
            Text("Or")
                .foregroundColor(.secondary)
            
            Button(action: { showQRScanner = true }) {
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text("Scan Existing QR")
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private var qrCodeDisplay: some View {
        VStack(spacing: 20) {
            Text("✓ QR Code Created")
                .font(.headline)
                .foregroundColor(.green)
            
            if let image = generatedQRImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 5)
            }
            
            Text(lockPointName)
                .font(.headline)
            
            HStack(spacing: 15) {
                Button(action: shareQR) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                Button(action: saveQR) {
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
    }
    
    private func generateQR() {
        let qrCode = "LOCKED://\(UUID().uuidString)"
        generatedQRCode = qrCode
        generatedQRImage = QRCodeService.generateQRCode(from: qrCode, size: 300)
        
        let lockPoint = LockPoint(name: lockPointName, qrCode: qrCode)
        onboardingManager.firstLockPoint = lockPoint
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func handleScannedCode(_ code: String) {
        showQRScanner = false
        guard QRCodeService.isValidLockPointQR(code) else { return }
        
        let lockPoint = LockPoint(name: "Lock Point 1", qrCode: code)
        onboardingManager.firstLockPoint = lockPoint
    }
    
    private func shareQR() {
        guard let image = generatedQRImage else { return }
        
        let activityController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func saveQR() {
        guard let image = generatedQRImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    CreateOrScanView(
        onboardingManager: OnboardingManager(),
        onNext: {}
    )
}
