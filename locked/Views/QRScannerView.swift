//
//  QRScannerView.swift
//  locked
//
//  QR Code scanner using AVFoundation
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    
    @State private var scannedCode: String?
    @State private var showingResult = false
    @State private var isScanning = true
    @Environment(\.dismiss) var dismiss
    
    var onCodeScanned: (String) -> Void
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(
                scannedCode: $scannedCode,
                isScanning: $isScanning
            )
            .edgesIgnoringSafeArea(.all)
            
            // Overlay UI
            VStack {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                // Scanning frame
                VStack(spacing: 20) {
                    Text(isScanning ? "Scan QR Code" : "Processing...")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                    
                    // Scanning rectangle guide
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            // Corner brackets
                            ZStack {
                                VStack {
                                    HStack {
                                        ScannerCorner()
                                        Spacer()
                                        ScannerCorner()
                                            .rotation3DEffect(.degrees(90), axis: (x: 0, y: 0, z: 1))
                                    }
                                    Spacer()
                                    HStack {
                                        ScannerCorner()
                                            .rotation3DEffect(.degrees(270), axis: (x: 0, y: 0, z: 1))
                                        Spacer()
                                        ScannerCorner()
                                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 0, z: 1))
                                    }
                                }
                                .padding(8)
                            }
                        )
                    
                    Text("Position QR code within frame")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Instructions
                VStack(spacing: 10) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text("Align the QR code within the frame")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(15)
                .padding(.bottom, 40)
            }
        }
        .onChange(of: scannedCode) { oldValue, newValue in
            if let code = newValue {
                handleScannedCode(code)
            }
        }
        .alert("QR Code Scanned", isPresented: $showingResult) {
            Button("OK") {
                isScanning = true
                scannedCode = nil
            }
        } message: {
            if let code = scannedCode {
                Text("Scanned: \(code)")
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        isScanning = false
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Validate if it's a lock point QR code
        if QRCodeService.isValidLockPointQR(code) {
            print("✅ Valid lock point QR: \(code)")
            onCodeScanned(code)
            
            // Dismiss after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        } else {
            print("⚠️ Invalid QR code format")
            showingResult = true
        }
    }
}

// MARK: - Scanner Corner Bracket

struct ScannerCorner: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 30, y: 0))
        }
        .stroke(Color.green, lineWidth: 4)
        .frame(width: 30, height: 30)
    }
}

// MARK: - Camera Preview (UIKit wrapper)

struct CameraPreview: UIViewRepresentable {
    
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        // Check camera authorization
        checkCameraAuthorization(for: view, context: context)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update scanning state
        if isScanning {
            context.coordinator.startScanning()
        } else {
            context.coordinator.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    private func checkCameraAuthorization(for view: UIView, context: Context) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            context.coordinator.setupCamera(in: view)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        context.coordinator.setupCamera(in: view)
                    }
                }
            }
        case .denied, .restricted:
            print("❌ Camera access denied")
        @unknown default:
            break
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: CameraPreview
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        init(parent: CameraPreview) {
            self.parent = parent
        }
        
        
        func setupCamera(in view: UIView) {
            let session = AVCaptureSession()
            
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                print("❌ Failed to get camera device")
                return
            }
            
            let videoInput: AVCaptureDeviceInput
            
            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                print("❌ Failed to create video input: \(error)")
                return
            }
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                print("❌ Could not add video input")
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                print("❌ Could not add metadata output")
                return
            }
            
            self.captureSession = session
            
            // FIX: Setup preview layer on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer.frame = view.bounds
                previewLayer.videoGravity = .resizeAspectFill
                view.layer.addSublayer(previewLayer)
                
                self.previewLayer = previewLayer
                
                // Start session on background thread
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                }
            }
        }
        
        
        func startScanning() {
            if let session = captureSession, !session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                }
            }
        }
        
        func stopScanning() {
            if let session = captureSession, session.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    session.stopRunning()
                }
            }
        }
        
        // MARK: - Metadata Delegate
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            
            guard parent.isScanning else { return }
            
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                parent.scannedCode = stringValue
            }
        }
    }
}

// MARK: - Preview

struct QRScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRScannerView { code in
            print("Scanned: \(code)")
        }
    }
}
