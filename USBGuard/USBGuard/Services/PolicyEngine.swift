//
//  PolicyEngine.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//  디바이스 연결 시 정책을 평가하고 허용/차단 결정

import Foundation

class PolicyEngine {
    static let shared = PolicyEngine()
    
    private var policies: [DevicePolicy] = []
    private let policyStorageKey = "com.usbguard.policies"
    
    private init() {
        loadPolicies()
        
        // 기본 정책 추가 (처음 실행 시)
        if policies.isEmpty {
            addDefaultPolicies()
        }
    }
    
    // MARK: - Policy Management
    func addPolicy(_ policy: DevicePolicy) {
        policies.append(policy)
        savePolicies()
    }
    
    func updatePolicy(_ policy: DevicePolicy) {
        if let index = policies.firstIndex(where: { $0.id == policy.id }) {
            var updated = policy
            updated.modifiedDate = Date()
            policies[index] = updated
            savePolicies()
        }
    }
    
    func removePolicy(_ id: UUID) {
        policies.removeAll { $0.id == id }
        savePolicies()
    }
    
    func getAllPolicies() -> [DevicePolicy] {
        return policies.filter { $0.enabled }
    }
    
    // MARK: - Policy Evaluation
    func evaluateDevice(_ device: USBDevice) -> (action: PolicyAction, matchedPolicy: DevicePolicy?) {
        print(" 정책 평가 시작: \(device.displayName)")
        
        // 활성화된 정책만 평가
        let activePolicies = policies.filter { $0.enabled }
        
        // 화이트리스트 우선 평가
        let whitelistPolicies = activePolicies.filter { $0.ruleType == .whitelist }
        for policy in whitelistPolicies {
            if matches(device: device, policy: policy) {
                print(" 화이트리스트 정책 매칭: \(policy.name)")
                return (policy.action, policy)
            }
        }
        
        // 블랙리스트 평가
        let blacklistPolicies = activePolicies.filter { $0.ruleType == .blacklist }
        for policy in blacklistPolicies {
            if matches(device: device, policy: policy) {
                print(" 블랙리스트 정책 매칭: \(policy.name)")
                return (.block, policy)
            }
        }
        
        // 매칭되는 정책 없음 - 기본 동작
        // 화이트리스트가 하나라도 있으면 기본은 차단
        if !whitelistPolicies.isEmpty {
            print("  화이트리스트 모드 - 기본 차단")
            return (.block, nil)
        }
        
        // 아무 정책도 없으면 기본 허용
        print(" 기본 정책 - 허용")
        return (.allow, nil)
    }
    
    // MARK: - Policy Matching
    private func matches(device: USBDevice, policy: DevicePolicy) -> Bool {
        // 조건이 없으면 모든 디바이스 매칭
        guard !policy.conditions.isEmpty else {
            return true
        }
        
        // 모든 조건이 AND로 연결됨
        for condition in policy.conditions {
            if !matches(device: device, condition: condition) {
                return false
            }
        }
        
        return true
    }
    
    private func matches(device: USBDevice, condition: PolicyCondition) -> Bool {
        switch condition {
        case .vendorID(let vid):
            return device.vendorID == vid
            
        case .productID(let pid):
            return device.productID == pid
            
        case .serialNumber(let serial):
            return device.serialNumber == serial
            
        case .deviceClass(let deviceClass):
            return device.deviceClass == deviceClass
            
        case .vendorName(let name):
            return device.vendorName.lowercased().contains(name.lowercased())
            
        case .timeRange(let start, let end):
            return isCurrentTimeInRange(start: start, end: end)
        }
    }
    
    private func isCurrentTimeInRange(start: String, end: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startTime = formatter.date(from: start),
              let endTime = formatter.date(from: end) else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        let currentTimeComponents = calendar.dateComponents([.hour, .minute], from: now)
        guard let currentTime = calendar.date(from: currentTimeComponents) else {
            return false
        }
        
        return currentTime >= startTime && currentTime <= endTime
    }
    
    // MARK: - Default Policies
    private func addDefaultPolicies() {
        // 1. 업무 시간 외 USB 차단
        let afterHoursPolicy = DevicePolicy(
            name: "업무 시간 외 USB 차단",
            enabled: false,
            ruleType: .blacklist,
            action: .block,
            conditions: [
                .deviceClass(.massStorage),
                .timeRange(start: "18:00", end: "09:00")
            ]
        )
        policies.append(afterHoursPolicy)
        
        // 2. 키보드/마우스는 항상 허용
        let inputDevicesPolicy = DevicePolicy(
            name: "입력 장치 허용",
            enabled: true,
            ruleType: .whitelist,
            action: .allow,
            conditions: [
                .deviceClass(.keyboard)
            ]
        )
        policies.append(inputDevicesPolicy)
        
        let mousePolicy = DevicePolicy(
            name: "마우스 허용",
            enabled: true,
            ruleType: .whitelist,
            action: .allow,
            conditions: [
                .deviceClass(.mouse)
            ]
        )
        policies.append(mousePolicy)
        
        // 3. 승인된 USB 제조사만 허용 (예시)
        let approvedVendorPolicy = DevicePolicy(
            name: "승인된 제조사 (예시: SanDisk)",
            enabled: false,
            ruleType: .whitelist,
            action: .allow,
            conditions: [
                .vendorName("SanDisk"),
                .deviceClass(.massStorage)
            ]
        )
        policies.append(approvedVendorPolicy)
        
        savePolicies()
    }
    
    // MARK: - Persistence
    private func savePolicies() {
        if let encoded = try? JSONEncoder().encode(policies) {
            UserDefaults.standard.set(encoded, forKey: policyStorageKey)
            print("정책 저장됨: \(policies.count)개")
        }
    }
    
    private func loadPolicies() {
        if let data = UserDefaults.standard.data(forKey: policyStorageKey),
           let decoded = try? JSONDecoder().decode([DevicePolicy].self, from: data) {
            policies = decoded
            print("정책 로드됨: \(policies.count)개")
        }
    }
}
