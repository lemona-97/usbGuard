//
//  ContentView.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: DeviceMonitorViewModel
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab: Hashable {
        case dashboard
        case devices
        case policies
        case logs
    }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("대시보드", systemImage: "chart.bar.fill")
                    .tag(Tab.dashboard)
                
                Label("디바이스", systemImage: "cable.connector")
                    .badge(viewModel.connectedDevices.count)
                    .tag(Tab.devices)
                
                Label("정책", systemImage: "shield.fill")
                    .tag(Tab.policies)
                
                Label("로그", systemImage: "doc.text.fill")
                    .badge(viewModel.accessLogs.count)
                    .tag(Tab.logs)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(viewModel: viewModel)
                case .devices:
                    DeviceListView(viewModel: viewModel)
                case .policies:
                    PolicyView()
                case .logs:
                    LogView(viewModel: viewModel)
                }
            }
        }
        .alert("디바이스 승인 필요", isPresented: $viewModel.showAlert) {
            Button("허용", role: .none) {
                viewModel.approveDevice()
            }
            Button("차단", role: .destructive) {
                viewModel.denyDevice()
            }
            Button("취소", role: .cancel) {
                viewModel.showAlert = false
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(DeviceMonitorViewModel())
        .frame(width: 1000, height: 700)
}
