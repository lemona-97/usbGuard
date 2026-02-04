//
//  IOKitService.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//  싱글턴 IOKit을 사용하여 USB 디바이스를 실시간으로 감지하고 모니터링


import Foundation
import IOKit
import IOKit.usb
import IOKit.storage

class IOKitService {
    static let shared = IOKitService()
    
    private var notificationPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    
    var onDeviceConnected: ((USBDevice) -> Void)?
    var onDeviceDisconnected: ((String) -> Void)?
    
    private init() {}
    
    // MARK: - Start Monitoring
    func startMonitoring() {
        print("🔍 IOKit USB 모니터링 시작...🔍 ")
        
        // Notification Port 생성
        notificationPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let notificationPort = notificationPort else {
            print("IONotificationPort 생성 실패")
            return
        }
        
        let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        
        // USB 디바이스 연결 감지
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        // 디바이스 추가 알림
        IOServiceAddMatchingNotification(
            notificationPort,
            kIOFirstMatchNotification,
            matchingDict,
            deviceAdded,
            selfPtr,
            &addedIterator
        )
        
        // 초기 디바이스 처리 (이미 연결된 디바이스)
        deviceAdded(refcon: selfPtr, iterator: addedIterator)
        
        // 디바이스 제거 알림
        let matchingDict2 = IOServiceMatching(kIOUSBDeviceClassName)
        IOServiceAddMatchingNotification(
            notificationPort,
            kIOTerminatedNotification,
            matchingDict2,
            deviceRemoved,
            selfPtr,
            &removedIterator
        )
        
        deviceRemoved(refcon: selfPtr, iterator: removedIterator)
        
        print("IOKit USB 모니터링 활성화")
    }
    
    func stopMonitoring() {
        if addedIterator != 0 {
            IOObjectRelease(addedIterator)
            addedIterator = 0
        }
        
        if removedIterator != 0 {
            IOObjectRelease(removedIterator)
            removedIterator = 0
        }
        
        if let port = notificationPort {
            IONotificationPortDestroy(port)
            notificationPort = nil
        }
        
        print("IOKit USB 모니터링 중지")
    }
    
    // MARK: - Get Connected Devices
    func getConnectedDevices() -> [USBDevice] {
        var devices: [USBDevice] = []
        
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        var iterator: io_iterator_t = 0
        
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        guard result == KERN_SUCCESS else {
            print("IOServiceGetMatchingServices 실패")
            return devices
        }
        
        defer { IOObjectRelease(iterator) }
        
        while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
            defer { IOObjectRelease(usbDevice) }
            
            if let device = extractDeviceInfo(from: usbDevice) {
                devices.append(device)
            }
        }
        
        return devices
    }
    
    // MARK: - Extract Device Info
   func extractDeviceInfo(from service: io_service_t) -> USBDevice? {
      let locationID = getProperty(service, key: "locationID") as? UInt64
      // registryEntryID 가져오기
      var registryID: UInt64 = 0
      IORegistryEntryGetRegistryEntryID(service, &registryID)
      
        // Vendor ID
        guard let vendorID = getProperty(service, key: kUSBVendorID) as? UInt16 else {
            return nil
        }
        
        // Product ID
        guard let productID = getProperty(service, key: kUSBProductID) as? UInt16 else {
            return nil
        }
        
        // Vendor Name
        let vendorName = getProperty(service, key: kUSBVendorString) as? String ?? "Unknown Vendor"
        
        // Product Name
        let productName = getProperty(service, key: kUSBProductString) as? String ?? "Unknown Device"
        
        // Serial Number
        let serialNumber = getProperty(service, key: kUSBSerialNumberString) as? String
        
        // Device Class 추론
        let deviceClass = inferDeviceClass(vendorID: vendorID, productID: productID, name: productName)
        
        // BSD Name 및 Mount Point (Storage 디바이스인 경우)
        var bsdName: String?
        var mountPoint: String?
        
        if deviceClass == .massStorage {
            (bsdName, mountPoint) = getStorageInfo(from: service)
        }
        
        return USBDevice(
            id: UUID(),
            physicalID: locationID.map{ UInt64($0) } ?? registryID ,
            vendorID: vendorID,
            productID: productID,
            vendorName: vendorName,
            productName: productName,
            serialNumber: serialNumber,
            deviceClass: deviceClass,
            connectionDate: Date(),
            bsdName: bsdName,
            mountPoint: mountPoint
        )
    }
    
    // MARK: - Helper Functions
   func getProperty(_ service: io_service_t, key: String) -> Any? {
        guard let property = IORegistryEntryCreateCFProperty(
            service,
            key as CFString,
            kCFAllocatorDefault,
            0
        ) else {
            return nil
        }
        
        return property.takeRetainedValue()
    }
    
    private func inferDeviceClass(vendorID: UInt16, productID: UInt16, name: String) -> DeviceClass {
        let lowerName = name.lowercased()
        
        // Apple iPhone / iPad (vendor specific)
        if vendorID == 0x05AC && !lowerName.contains("keyboard") && !lowerName.contains("trackpad") && !lowerName.contains("mouse") {
            return .appleMobile
        }
        
        // 이름 기반 추론
        if lowerName.contains("keyboard") {
            return .keyboard
        } else if lowerName.contains("mouse") || lowerName.contains("trackpad") {
            return .mouse
        } else if lowerName.contains("storage") || lowerName.contains("disk") || lowerName.contains("flash") {
            return .massStorage
        } else if lowerName.contains("hub") {
            return .hub
        } else if lowerName.contains("printer") {
            return .printer
        } else if lowerName.contains("camera") || lowerName.contains("webcam") {
            return .camera
        } else if lowerName.contains("audio") || lowerName.contains("speaker") || lowerName.contains("headphone") {
            return .audio
        } else if lowerName.contains("network") || lowerName.contains("ethernet") {
            return .network
        } else if lowerName.contains("bluetooth") {
            return .bluetooth
        }
        
        // Vendor ID 기반 추론 (일부 알려진 제조사)
        // 추가 로직 가능
        
        return .unknown
    }
    
    private func getStorageInfo(from service: io_service_t) -> (bsdName: String?, mountPoint: String?) {
        // Storage 디바이스의 BSD name과 mount point를 찾음
        // 실제 구현은 IOStorageFamily를 통해 더 복잡하게 처리 가능
        
        var iterator: io_iterator_t = 0
        let result = IORegistryEntryCreateIterator(
            service,
            kIOServicePlane,
            IOOptionBits(kIORegistryIterateRecursively),
            &iterator
        )
        
        guard result == KERN_SUCCESS else { return (nil, nil) }
        defer { IOObjectRelease(iterator) }
        
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            
            if let bsdName = getProperty(entry, key: "BSD Name") as? String {
                let mountPoint = findMountPoint(for: bsdName)
                return (bsdName, mountPoint)
            }
        }
        
        return (nil, nil)
    }
    
    private func findMountPoint(for bsdName: String) -> String? {
        // /dev/diskX 형태로 변환
        let devicePath = "/dev/\(bsdName)"
        
        // mount 명령 실행하여 마운트 포인트 찾기
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/sbin/mount")
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // 출력 파싱하여 마운트 포인트 찾기
                let lines = output.components(separatedBy: "\n")
                for line in lines {
                    if line.contains(devicePath) {
                        let components = line.components(separatedBy: " on ")
                        if components.count >= 2 {
                            let mountInfo = components[1].components(separatedBy: " (")
                            return mountInfo.first
                        }
                    }
                }
            }
        } catch {
            print("mount 명령 실행 실패: \(error)")
        }
        
        return nil
    }
}

// MARK: - IOKit Callback Functions
private func deviceAdded(refcon: UnsafeMutableRawPointer?, iterator: io_iterator_t) {
    let service = Unmanaged<IOKitService>.fromOpaque(refcon!).takeUnretainedValue()
    
    while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
        defer { IOObjectRelease(usbDevice) }
        
        if let device = service.extractDeviceInfo(from: usbDevice) {
            print("USB 디바이스 연결: \(device.displayName)")
            service.onDeviceConnected?(device)
        }
    }
}

private func deviceRemoved(refcon: UnsafeMutableRawPointer?, iterator: io_iterator_t) {
    let service = Unmanaged<IOKitService>.fromOpaque(refcon!).takeUnretainedValue()
    
    while case let usbDevice = IOIteratorNext(iterator), usbDevice != 0 {
        defer { IOObjectRelease(usbDevice) }
        
        // 제거된 디바이스의 정보는 제한적이므로, ID만 전달
        // 실제로는 연결 시 ID를 저장해두었다가 매칭하는 로직 필요
        if let vendorID = service.getProperty(usbDevice, key: kUSBVendorID) as? UInt16,
           let productID = service.getProperty(usbDevice, key: kUSBProductID) as? UInt16 {
            let deviceID = "VID:\(String(format: "%04X", vendorID))-PID:\(String(format: "%04X", productID))"
            print("❌ USB 디바이스 연결 해제: \(deviceID)")
            service.onDeviceDisconnected?(deviceID)
        }
    }
}

// MARK: - IOKit Constants
private let kUSBVendorID = "idVendor"
private let kUSBProductID = "idProduct"
private let kUSBVendorString = "USB Vendor Name"
private let kUSBProductString = "USB Product Name"
private let kUSBSerialNumberString = "USB Serial Number"
