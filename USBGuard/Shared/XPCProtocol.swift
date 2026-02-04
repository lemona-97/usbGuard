//
//  XPCProtocol.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//  Main App과 System Extension 간 통신 프로토콜

import Foundation

// MARK: - XPC Protocol
@objc protocol USBGuardXPCProtocol {
    /// Extension에서 Main App으로 디바이스 이벤트 전송
    func deviceConnected(_ device: Data, reply: @escaping (Bool) -> Void)
    func deviceDisconnected(_ deviceID: String, reply: @escaping (Bool) -> Void)
    
    /// Main App에서 Extension으로 정책 업데이트
    func updatePolicies(_ policies: Data, reply: @escaping (Bool) -> Void)
    
    /// 연결된 디바이스 목록 요청
    func getConnectedDevices(reply: @escaping (Data?) -> Void)
    
    /// Extension 상태 확인
    func getExtensionStatus(reply: @escaping (Bool) -> Void)
    
    /// 로그 이벤트 전송
    func logEvent(_ event: Data, reply: @escaping (Bool) -> Void)
}

// MARK: - XPC Constants
enum XPCConstants {
    static let machServiceName = "com.usbguard.extension"
    static let appGroupIdentifier = "group.com.usbguard.shared"
}

// MARK: - XPC Helper (인코딩/디코딩)
enum XPCHelper {
    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }
    
    static func decode<T: Decodable>(_ data: Data) -> T? {
        try? JSONDecoder().decode(T.self, from: data)
    }
}
