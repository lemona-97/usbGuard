//
//  MainBarView.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//

import SwiftUI

// MARK: - Menu Bar View
struct MenuBarView: View {
    @EnvironmentObject var viewModel: DeviceMonitorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("USBGuard")
                .font(.headline)
            
            Divider()
            
            HStack {
                Image(systemName: viewModel.isMonitoring ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.isMonitoring ? .green : .red)
                Text(viewModel.isMonitoring ? "모니터링 활성" : "모니터링 비활성")
            }
            
            Text("연결된 디바이스: \(viewModel.connectedDevices.count)")
                .font(.caption)
            
            Divider()
            
            Button(viewModel.isMonitoring ? "모니터링 중지" : "모니터링 시작") {
                if viewModel.isMonitoring {
                    viewModel.stopMonitoring()
                } else {
                    viewModel.startMonitoring()
                }
            }
            
            Divider()
            
            Button("종료") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
    }
}
