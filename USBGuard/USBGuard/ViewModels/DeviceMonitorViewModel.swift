//
//  DeviceMonitorViewModel.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//

import Foundation
import Combine
import DiskArbitration

@MainActor
class DeviceMonitorViewModel: ObservableObject {
   @Published var connectedDevices: [USBDevice] = []
   @Published var accessLogs: [AccessLog] = []
   @Published var statistics = DeviceStatistics()
   @Published var isMonitoring = false
   @Published var showAlert = false
   @Published var alertMessage = ""
   @Published var pendingDevice: USBDevice?
   @Published var pendingAction: PolicyAction?
   
   private let ioKitService = IOKitService.shared
   private let policyEngine = PolicyEngine.shared
   private let logsStorageKey = "com.usbguard.logs"
   private let maxLogs = 1000
   
   init() {
      setupCallbacks()
      loadLogs()
      loadStatistics()
   }
   
   // MARK: - Monitoring Control
   func startMonitoring() {
      guard !isMonitoring else { return }
      
      ioKitService.startMonitoring()
      
      // 현재 연결된 디바이스 가져오기
      let devices = ioKitService.getConnectedDevices()
      connectedDevices = devices
      
      isMonitoring = true
      print("디바이스 모니터링 시작됨")
   }
   
   func stopMonitoring() {
      guard isMonitoring else { return }
      
      ioKitService.stopMonitoring()
      isMonitoring = false
      print("디바이스 모니터링 중지됨")
   }
   
   // MARK: - Device Event Handlers
   private func setupCallbacks() {
      ioKitService.onDeviceConnected = { [weak self] device in
         Task { @MainActor in
            self?.handleDeviceConnected(device)
         }
      }
      
      ioKitService.onDeviceDisconnected = { [weak self] deviceID in
         Task { @MainActor in
            self?.handleDeviceDisconnected(deviceID)
         }
      }
   }
   
   private func handleDeviceConnected(_ device: USBDevice) {
      print("디바이스 연결됨: \(device.displayName)")
      
      // iPhone / iPad 즉시 차단 테스트
      if device.deviceClass == .appleMobile {
          let log = AccessLog(
              device: device,
              eventType: .blocked,
              action: .block,
              policyName: "iOS Device Block",
              detail: "Apple iOS 디바이스 자동 차단"
          )
          connectedDevices.append(device)
          addLog(log)
          statistics.recordEvent(device, action: .block)
          saveStatistics()
          blockDevice(device, policy: nil)
          return
      }
      
      // 정책 평가
      let (action, matchedPolicy) = policyEngine.evaluateDevice(device)
      
      // 디바이스를 목록에 추가
      connectedDevices.append(device)
      
      // 로그 기록
      let log = AccessLog(
         device: device,
         eventType: .connected,
         action: action,
         policyName: matchedPolicy?.name,
         detail: "정책: \(matchedPolicy?.name ?? "기본")"
      )
      addLog(log)
      
      // 통계 업데이트
      statistics.recordEvent(device, action: action)
      saveStatistics()
      
      // 액션 실행
      executeAction(action, for: device, policy: matchedPolicy)
   }
   
   private func handleDeviceDisconnected(_ deviceID: String) {
      print("디바이스 연결 해제: \(deviceID)")
      
      // 목록에서 제거
      if let index = connectedDevices.firstIndex(where: { $0.identifierString == deviceID }) {
         let device = connectedDevices[index]
         connectedDevices.remove(at: index)
         
         // 로그 기록
         let log = AccessLog(
            device: device,
            eventType: .disconnected,
            action: .allow,
            detail: "정상적으로 연결 해제됨"
         )
         addLog(log)
      }
   }
   
   // MARK: - Policy Actions
   private func executeAction(_ action: PolicyAction, for device: USBDevice, policy: DevicePolicy?) {
      switch action {
      case .allow:
         print("디바이스 허용: \(device.displayName)")
         showNotification(
            title: "디바이스 허용됨",
            message: "\(device.displayName)이(가) 연결되었습니다."
         )
         
      case .block:
         print("디바이스 차단: \(device.displayName)")
         blockDevice(device, policy: policy)
         
      case .readOnly:
         print("읽기 전용 모드: \(device.displayName)")
         setReadOnlyMode(device)
         
      case .askUser:
         print("사용자 확인 필요: \(device.displayName)")
         requestUserApproval(device, policy: policy)
      }
   }
   
   private func blockDevice(_ device: USBDevice, policy: DevicePolicy?) {
      // 실제 차단 로직 - 마운트 해제 또는 접근 거부
      // System Extension에서 처리하는 것이 더 효과적

      if device.deviceClass == .appleMobile {
          // iPhone / iPad 논리적 차단 처리
          // user-space에서는 실제 USB 통신 차단이 불가능하므로
          // 1) 정책 차단 상태 유지
          // 2) 페어링/접근 시도에 대한 명확한 로그 남김

          print("🚫 Apple iOS 디바이스 차단 처리 시작")
          print(" - 디바이스 이름: \(device.displayName)")
          print(" - Vendor ID: \(String(format: "0x%04X", device.vendorID))")
          print(" - Product ID: \(String(format: "0x%04X", device.productID))")

          // 향후 System Extension 연동 포인트
          // sendBlockRequestToSystemExtension(device)
         
          return
      }

      showNotification(
         title: "디바이스 차단됨",
         message: "\(device.displayName)이(가) 정책에 의해 차단되었습니다.\n정책: \(policy?.name ?? "기본")"
      )

      let log = AccessLog(
         device: device,
         eventType: .blocked,
         action: .block,
         policyName: policy?.name,
         detail: "정책에 의해 차단됨"
      )
      addLog(log)
   }
   
   private func setReadOnlyMode(_ device: USBDevice) {
      // 마운트 옵션을 읽기 전용으로 변경
      // 실제로는 diskutil remount readonly 명령 사용 가능
      
      showNotification(
         title: "읽기 전용 모드",
         message: "\(device.displayName)이(가) 읽기 전용으로 마운트되었습니다."
      )
      
      let log = AccessLog(
         device: device,
         eventType: .allowed,
         action: .readOnly,
         detail: "읽기 전용 모드로 허용됨"
      )
      addLog(log)
   }
   
   private func requestUserApproval(_ device: USBDevice, policy: DevicePolicy?) {
      pendingDevice = device
      pendingAction = .askUser
      alertMessage = """
        새로운 USB 디바이스가 연결되었습니다.
        
        디바이스: \(device.displayName)
        제조사: \(device.vendorName)
        타입: \(device.deviceClass.rawValue)
        
        이 디바이스를 허용하시겠습니까?
        """
      showAlert = true
   }
   
   func approveDevice() {
      guard let device = pendingDevice else { return }
      
      let log = AccessLog(
         device: device,
         eventType: .allowed,
         action: .allow,
         detail: "사용자가 수동으로 승인함"
      )
      addLog(log)
      
      showNotification(
         title: "✅ 디바이스 승인됨",
         message: "\(device.displayName)이(가) 사용자에 의해 승인되었습니다."
      )
      
      pendingDevice = nil
      pendingAction = nil
      showAlert = false
   }
   
   func denyDevice() {
      guard let device = pendingDevice else { return }
      
      blockDevice(device, policy: nil)
      
      pendingDevice = nil
      pendingAction = nil
      showAlert = false
   }
   
   // MARK: - Logging
   private func addLog(_ log: AccessLog) {
      accessLogs.insert(log, at: 0)
      
      // 최대 로그 개수 유지
      if accessLogs.count > maxLogs {
         accessLogs.removeLast(accessLogs.count - maxLogs)
      }
      
      saveLogs()
   }
   
   func clearLogs() {
      accessLogs.removeAll()
      saveLogs()
   }
   
   private func saveLogs() {
      if let encoded = try? JSONEncoder().encode(accessLogs) {
         UserDefaults.standard.set(encoded, forKey: logsStorageKey)
      }
   }
   
   private func loadLogs() {
      if let data = UserDefaults.standard.data(forKey: logsStorageKey),
         let decoded = try? JSONDecoder().decode([AccessLog].self, from: data) {
         accessLogs = decoded
      }
   }
   
   // MARK: - Statistics
   private func saveStatistics() {
      if let encoded = try? JSONEncoder().encode(statistics) {
         UserDefaults.standard.set(encoded, forKey: "com.usbguard.statistics")
      }
   }
   
   private func loadStatistics() {
      if let data = UserDefaults.standard.data(forKey: "com.usbguard.statistics"),
         let decoded = try? JSONDecoder().decode(DeviceStatistics.self, from: data) {
         statistics = decoded
      }
   }
   
   func resetStatistics() {
      statistics = DeviceStatistics()
      saveStatistics()
   }
   
   // MARK: - Notifications
   private func showNotification(title: String, message: String) {
      // UserNotifications 프레임워크 사용
      // 실제 구현 시 권한 요청 필요
      print("알림: \(title) - \(message)")
      
      // 간단한 alert로 대체 (데모용)
      DispatchQueue.main.async { [weak self] in
         self?.alertMessage = message
         // showAlert = true 대신 별도 알림 표시 가능
      }
   }
}
