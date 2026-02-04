//
//  USBDevice.swift
//  USBGuard
//
//  Created by wooseob on 2/3/26.
//  USB 디바이스 관련 모델

import Foundation

struct USBDevice: Identifiable, Codable, Hashable {
    let id: UUID
    let physicalID: UInt64         // locationID or registryID
    let vendorID: UInt16          // USB Vendor ID
    let productID: UInt16         // USB Product ID
    let vendorName: String
    let productName: String
    let serialNumber: String?
    let deviceClass: DeviceClass
    let connectionDate: Date
    let bsdName: String?          // 예: /dev/disk2
    let mountPoint: String?       // 예: /Volumes/USB_DRIVE
    
    var displayName: String {
        "\(vendorName) \(productName)"
    }
    
    var identifierString: String {
        if let serial = serialNumber, !serial.isEmpty {
            return "VID:\(String(format: "%04X", vendorID))-PID:\(String(format: "%04X", productID))-SN:\(serial)"
        }
        return "VID:\(String(format: "%04X", vendorID))-PID:\(String(format: "%04X", productID))"
    }
}

// MARK: - Device Class
enum DeviceClass: String, Codable, CaseIterable {
    case appleMobile = "Apple iOS Device" // iPhone, iPad
    case massStorage = "Mass Storage"
    case keyboard = "Keyboard"
    case mouse = "Mouse"
    case hub = "Hub"
    case printer = "Printer"
    case camera = "Camera"
    case audio = "Audio"
    case network = "Network"
    case bluetooth = "Bluetooth"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .appleMobile: return "apple.logo"
        case .massStorage: return "externaldrive.fill"
        case .keyboard: return "keyboard.fill"
        case .mouse: return "mouse.fill"
        case .hub: return "point.3.connected.trianglepath.dotted"
        case .printer: return "printer.fill"
        case .camera: return "camera.fill"
        case .audio: return "headphones"
        case .network: return "network"
        case .bluetooth: return "antenna.radiowaves.left.and.right"
        case .unknown: return "questionmark.circle"
        }
    }
}
