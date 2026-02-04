//
//  LogView.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//  디바이스 접근 로그 및 이벤트 히스토리

//
//  LogView.swift
//  USBGuard - Access Logs
//
//  디바이스 접근 로그 및 이벤트 히스토리
//

import SwiftUI

struct LogView: View {
    @ObservedObject var viewModel: DeviceMonitorViewModel
    @State private var searchText = ""
    @State private var selectedEventType: LogEventType?
    
    var filteredLogs: [AccessLog] {
        var logs = viewModel.accessLogs
        
        if !searchText.isEmpty {
            logs = logs.filter { log in
                log.device.displayName.localizedCaseInsensitiveContains(searchText) ||
                log.device.vendorName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let eventType = selectedEventType {
            logs = logs.filter { $0.eventType == eventType }
        }
        
        return logs
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 검색 및 필터
            VStack(spacing: 12) {
                // 검색바
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("로그 검색...", text: $searchText)
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
                
                // 필터 버튼
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterButton(
                            title: "전체",
                            isSelected: selectedEventType == nil,
                            action: { selectedEventType = nil }
                        )
                        
                        FilterButton(
                            title: "연결됨",
                            icon: "cable.connector",
                            isSelected: selectedEventType == .connected,
                            action: { selectedEventType = .connected }
                        )
                        
                        FilterButton(
                            title: "차단됨",
                            icon: "xmark.shield.fill",
                            isSelected: selectedEventType == .blocked,
                            action: { selectedEventType = .blocked }
                        )
                        
                        FilterButton(
                            title: "허용됨",
                            icon: "checkmark.shield.fill",
                            isSelected: selectedEventType == .allowed,
                            action: { selectedEventType = .allowed }
                        )
                    }
                }
            }
            .padding()
            
            Divider()
            
            // 로그 목록
            if filteredLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty && selectedEventType == nil ? "아직 로그가 없습니다" : "검색 결과 없음")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredLogs) { log in
                    HStack(spacing: 12) {
                        Image(systemName: log.eventType.icon)
                            .font(.title3)
                            .foregroundColor(colorForEventType(log.eventType))
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.device.displayName)
                                .font(.headline)
                            
                            HStack(spacing: 8) {
                                Text(log.eventType.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(colorForEventType(log.eventType).opacity(0.2))
                                    .cornerRadius(4)
                                
                                if let policyName = log.policyName {
                                    Text("정책: \(policyName)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(log.timestamp.formatted(date: .numeric, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("📜 접근 로그")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        viewModel.clearLogs()
                    }) {
                        Label("로그 지우기", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    private func colorForEventType(_ type: LogEventType) -> Color {
        switch type.color {
        case "green": return .green
        case "red": return .red
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        default: return .gray
        }
    }
}

struct FilterButton: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.controlBackgroundColor))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LogView(viewModel: DeviceMonitorViewModel())
        .frame(width: 800, height: 600)
}
