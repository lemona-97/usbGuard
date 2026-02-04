//
//  DeviceListView.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//  현재 연결된 USB 디바이스 목록 및 상세 정보

import SwiftUI

struct DeviceListView: View {
    @ObservedObject var viewModel: DeviceMonitorViewModel
    @State private var selectedDevice: USBDevice?
    @State private var searchText = ""
    
    var filteredDevices: [USBDevice] {
        if searchText.isEmpty {
            return viewModel.connectedDevices
        }
        return viewModel.connectedDevices.filter { device in
            device.displayName.localizedCaseInsensitiveContains(searchText) ||
            device.vendorName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 검색바
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("디바이스 검색...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(.textBackgroundColor))
            .cornerRadius(8)
            .padding()
            
            Divider()
            
            // 디바이스 목록
            if filteredDevices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cable.connector.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "연결된 디바이스 없음" : "검색 결과 없음")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredDevices) { device in
                    HStack(spacing: 12) {
                        Image(systemName: device.deviceClass.icon)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.productName)
                                .font(.headline)
                            
                            Text(device.vendorName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if device.deviceClass == .massStorage {
                            Image(systemName: device.mountPoint != nil ? "externaldrive.fill.badge.checkmark" : "externaldrive.fill")
                                .foregroundColor(device.mountPoint != nil ? .green : .orange)
                        }
                        
                        Button {
                            selectedDevice = device
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("🔌 연결된 디바이스")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    viewModel.startMonitoring()
                }) {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }
            }
        }
        .sheet(item: $selectedDevice) { device in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // 헤더
                        HStack(spacing: 16) {
                            Image(systemName: device.deviceClass.icon)
                                .font(.system(size: 48))
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.productName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(device.vendorName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(12)
                        
                        // 기본 정보
                        VStack(alignment: .leading, spacing: 12) {
                            Text("기본 정보")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("디바이스 타입")
                                        .foregroundColor(.secondary)
                                        .frame(width: 120, alignment: .leading)
                                    Text(device.deviceClass.rawValue)
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Vendor ID")
                                        .foregroundColor(.secondary)
                                        .frame(width: 120, alignment: .leading)
                                    Text(String(format: "0x%04X", device.vendorID))
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Product ID")
                                        .foregroundColor(.secondary)
                                        .frame(width: 120, alignment: .leading)
                                    Text(String(format: "0x%04X", device.productID))
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                                
                                if let serial = device.serialNumber {
                                    HStack {
                                        Text("시리얼 번호")
                                            .foregroundColor(.secondary)
                                            .frame(width: 120, alignment: .leading)
                                        Text(serial)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                }
                                
                                HStack {
                                    Text("연결 시간")
                                        .foregroundColor(.secondary)
                                        .frame(width: 120, alignment: .leading)
                                    Text(device.connectionDate.formatted())
                                        .fontWeight(.medium)
                                    Spacer()
                                }
                            }
                            .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(12)
                        
                        // 스토리지 정보
                        if device.deviceClass == .massStorage {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("스토리지 정보")
                                    .font(.headline)
                                
                                VStack(spacing: 8) {
                                    if let bsdName = device.bsdName {
                                        HStack {
                                            Text("BSD Name")
                                                .foregroundColor(.secondary)
                                                .frame(width: 120, alignment: .leading)
                                            Text(bsdName)
                                                .fontWeight(.medium)
                                            Spacer()
                                        }
                                    }
                                    
                                    HStack {
                                        Text("마운트 포인트")
                                            .foregroundColor(.secondary)
                                            .frame(width: 120, alignment: .leading)
                                        Text(device.mountPoint ?? "마운트되지 않음")
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                }
                                .font(.subheadline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.windowBackgroundColor))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
                .navigationTitle("디바이스 상세")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("닫기") {
                            selectedDevice = nil
                        }
                    }
                }
            }
            .frame(width: 500, height: 600)
        }
    }
}

#Preview {
    DeviceListView(viewModel: DeviceMonitorViewModel())
        .frame(width: 800, height: 600)
}
