
//
//  QRCodeService.swift
//  locked
//
//  QR Code generation service using Core Image
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

class QRCodeService {
    
    // MARK: - QR Code Generation
    
    /// Generates a QR code image from a string
    /// - Parameters:
    ///   - string: The data to encode in the QR code
    ///   - size: The size of the output image (default: 200x200)
    /// - Returns: UIImage of the QR code, or nil if generation fails
    static func generateQRCode(from string: String, size: CGFloat = 200) -> UIImage? {
        // Create the QR code filter
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        // Convert string to Data
        guard let data = string.data(using: .utf8) else {
            print("❌ Failed to convert string to data")
            return nil
        }
        
        // Set the data for the QR code
        filter.message = data
        filter.correctionLevel = "M" // Medium error correction
        
        // Get the output image
        guard let outputImage = filter.outputImage else {
            print("❌ Failed to generate QR code image")
            return nil
        }
        
        // Scale the image to desired size
        let scaleX = size / outputImage.extent.size.width
        let scaleY = size / outputImage.extent.size.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert to UIImage
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            print("❌ Failed to create CGImage")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Lock Point QR Code Generation
    
    /// Generates a unique QR code for a lock point
    /// - Parameters:
    ///   - lockPointID: Unique identifier for the lock point
    ///   - timestamp: Optional timestamp for time-based codes
    /// - Returns: UIImage of the QR code
    static func generateLockPointQR(lockPointID: String, timestamp: Date? = nil) -> UIImage? {
        var qrString = "LOCKED://\(lockPointID)"
        
        // Add timestamp if provided (for time-based codes)
        if let timestamp = timestamp {
            let interval = Int(timestamp.timeIntervalSince1970)
            qrString += "/\(interval)"
        }
        
        // Get device ID for security
        if let deviceID = UIDevice.current.identifierForVendor?.uuidString {
            qrString += "/\(deviceID)"
        }
        
        print("🔐 Generating QR code: \(qrString)")
        return generateQRCode(from: qrString, size: 300)
    }
    
    // MARK: - Helper Functions
    
    /// Validates QR code string format
    static func isValidLockPointQR(_ string: String) -> Bool {
        return string.hasPrefix("LOCKED://")
    }
    
    /// Extracts lock point ID from QR code string
    static func extractLockPointID(from string: String) -> String? {
        guard isValidLockPointQR(string) else { return nil }
        
        let components = string.replacingOccurrences(of: "LOCKED://", with: "").components(separatedBy: "/")
        return components.first
    }
}
