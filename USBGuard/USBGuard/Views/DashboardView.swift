//
//  DashboardView.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//  메인 대시보드: 통계 및 실시간 모니터링 현황

import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var viewModel: DeviceMonitorViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 모니터링 상태
                monitoringStatusCard
                
                // 통계 카드
                statisticsCards
                
                // 최근 이벤트
                recentEventsCard
                
                // 디바이스 타입 분포
                deviceTypeChart
            }
            .padding()
        }
        .navigationTitle("대시보드")
    }
    
    // MARK: - Monitoring Status
    private var monitoringStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: viewModel.isMonitoring ? "checkmark.shield.fill" : "xmark.shield.fill")
                    .font(.system(size: 40))
                    .foregroundColor(viewModel.isMonitoring ? .green : .red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("모니터링 상태")
                        .font(.headline)
                    Text(viewModel.isMonitoring ? "활성화됨" : "비활성화됨")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.isMonitoring ? .green : .red)
                }
                
                Spacer()
                
                Button(action: {
                    if viewModel.isMonitoring {
                        viewModel.stopMonitoring()
                    } else {
                        viewModel.startMonitoring()
                    }
                }) {
                    Text(viewModel.isMonitoring ? "중지" : "시작")
                        .fontWeight(.semibold)
                        .frame(width: 80)
                        .padding(.vertical, 8)
                        .background(viewModel.isMonitoring ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            Divider()
            
            HStack(spacing: 30) {
                StatItem(
                    icon: "cable.connector",
                    value: "\(viewModel.connectedDevices.count)",
                    label: "연결된 디바이스"
                )
                
                StatItem(
                    icon: "clock.fill",
                    value: viewModel.statistics.lastUpdated.formatted(date: .omitted, time: .shortened),
                    label: "마지막 업데이트"
                )
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Statistics Cards
    private var statisticsCards: some View {
        HStack(spacing: 15) {
            StatCard(
                title: "총 연결",
                value: "\(viewModel.statistics.totalConnections)",
                icon: "cable.connector",
                color: .blue
            )
            
            StatCard(
                title: "허용됨",
                value: "\(viewModel.statistics.totalAllowed)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "차단됨",
                value: "\(viewModel.statistics.totalBlocked)",
                icon: "xmark.circle.fill",
                color: .red
            )
        }
    }
    
    // MARK: - Recent Events
    private var recentEventsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 이벤트")
                    .font(.headline)
                Spacer()
                if !viewModel.accessLogs.isEmpty {
                    Button("전체 보기") {
                        // Navigate to logs view
                    }
                    .font(.caption)
                }
            }
            
            if viewModel.accessLogs.isEmpty {
                Text("아직 이벤트가 없습니다")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.accessLogs.prefix(5))) { log in
                        EventRow(log: log)
                    }
                }
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Device Type Chart
    private var deviceTypeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("디바이스 타입 분포")
                .font(.headline)
            
            if viewModel.statistics.deviceTypeBreakdown.isEmpty {
                Text("데이터 없음")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(Array(viewModel.statistics.deviceTypeBreakdown.keys), id: \.self) { deviceClass in
                        if let count = viewModel.statistics.deviceTypeBreakdown[deviceClass] {
                            BarMark(
                                x: .value("개수", count),
                                y: .value("타입", deviceClass.rawValue)
                            )
                            .foregroundStyle(by: .value("타입", deviceClass.rawValue))
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Supporting Views
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EventRow: View {
    let log: AccessLog
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.eventType.icon)
                .foregroundColor(colorForEventType(log.eventType))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.device.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(log.eventType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(log.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
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

#Preview {
    DashboardView(viewModel: DeviceMonitorViewModel())
        .frame(width: 800, height: 600)
}
