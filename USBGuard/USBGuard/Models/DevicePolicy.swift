//
//  DevicePolicy.swift
//  USBGuard
//
//  Created by wooseob on 2/3/26.
//  정책 관련 데이터 모델

import Foundation

struct DevicePolicy: Identifiable, Codable {
    let id: UUID
    var name: String
    var enabled: Bool
    var ruleType: RuleType
    var action: PolicyAction
    var conditions: [PolicyCondition]
    var createdDate: Date
    var modifiedDate: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        enabled: Bool = true,
        ruleType: RuleType,
        action: PolicyAction,
        conditions: [PolicyCondition] = [],
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.ruleType = ruleType
        self.action = action
        self.conditions = conditions
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }
}

enum RuleType: String, Codable, CaseIterable {
    case whitelist = "화이트리스트"
    case blacklist = "블랙리스트"
    
    var description: String {
        switch self {
        case .whitelist: return "허용 목록에 있는 디바이스만 접근 가능"
        case .blacklist: return "차단 목록에 있는 디바이스는 접근 불가"
        }
    }
}

enum PolicyAction: String, Codable, CaseIterable {
    case allow = "허용"
    case block = "차단"
    case readOnly = "읽기 전용"
    case askUser = "사용자에게 묻기"
    
    var icon: String {
        switch self {
        case .allow: return "checkmark.circle.fill"
        case .block: return "xmark.circle.fill"
        case .readOnly: return "eye.fill"
        case .askUser: return "questionmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .allow: return "green"
        case .block: return "red"
        case .readOnly: return "orange"
        case .askUser: return "blue"
        }
    }
}

// MARK: - Policy Condition
enum PolicyCondition: Codable, Hashable {
    case vendorID(UInt16)
    case productID(UInt16)
    case serialNumber(String)
    case deviceClass(DeviceClass)
    case vendorName(String)
    case timeRange(start: String, end: String)  // "09:00", "18:00"
    
    var description: String {
        switch self {
        case .vendorID(let id):
            return "Vendor ID: \(String(format: "0x%04X", id))"
        case .productID(let id):
            return "Product ID: \(String(format: "0x%04X", id))"
        case .serialNumber(let serial):
            return "Serial: \(serial)"
        case .deviceClass(let deviceClass):
            return "Type: \(deviceClass.rawValue)"
        case .vendorName(let name):
            return "제조사: \(name)"
        case .timeRange(let start, let end):
            return "시간: \(start) - \(end)"
        }
    }
}
