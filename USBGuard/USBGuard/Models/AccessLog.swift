//
//  AccessLog.swift
//  USBGuard
//
//  Created by wooseob on 2/3/26.
//

import Foundation

struct AccessLog: Identifiable, Hashable, Codable {
    let id: UUID
    let device: USBDevice
    let timestamp: Date
    let eventType: LogEventType
    let action: PolicyAction
    let policyName: String?
    let detail: String?
    
    init(
        id: UUID = UUID(),
        device: USBDevice,
        timestamp: Date = Date(),
        eventType: LogEventType,
        action: PolicyAction,
        policyName: String? = nil,
        detail: String? = nil
    ) {
        self.id = id
        self.device = device
        self.timestamp = timestamp
        self.eventType = eventType
        self.action = action
        self.policyName = policyName
        self.detail = detail
    }
}

enum LogEventType: String, Codable {
    case connected = "연결됨"
    case disconnected = "연결 해제됨"
    case allowed = "허용됨"
    case blocked = "차단됨"
    case mounted = "마운트됨"
    case unmounted = "마운트 해제됨"
    case fileAccess = "파일 접근"
    
    var icon: String {
        switch self {
        case .connected: return "cable.connector"
        case .disconnected: return "cable.connector.slash"
        case .allowed: return "checkmark.shield.fill"
        case .blocked: return "xmark.shield.fill"
        case .mounted: return "externaldrive.badge.checkmark"
        case .unmounted: return "externaldrive.badge.xmark"
        case .fileAccess: return "doc.fill"
        }
    }
    
    var color: String {
        switch self {
        case .connected: return "blue"
        case .disconnected: return "gray"
        case .allowed: return "green"
        case .blocked: return "red"
        case .mounted: return "green"
        case .unmounted: return "orange"
        case .fileAccess: return "purple"
        }
    }
}

// MARK: - Statistics
struct DeviceStatistics: Codable {
    var totalConnections: Int = 0
    var totalBlocked: Int = 0
    var totalAllowed: Int = 0
    var deviceTypeBreakdown: [DeviceClass: Int] = [:]
    var lastUpdated: Date = Date()
    
    mutating func recordEvent(_ device: USBDevice, action: PolicyAction) {
        totalConnections += 1
        
        switch action {
        case .allow, .readOnly, .askUser:
            totalAllowed += 1
        case .block:
            totalBlocked += 1
        }
        
        deviceTypeBreakdown[device.deviceClass, default: 0] += 1
        lastUpdated = Date()
    }
}
