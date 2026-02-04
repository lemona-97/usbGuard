//
//  USBGuardApp.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//  macOS USB 디바이스 제어 및 모니터링 앱

import SwiftUI

@main
struct USBGuardApp: App {
    @StateObject private var viewModel = DeviceMonitorViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    // 앱 시작 시 자동으로 모니터링 시작
                    viewModel.startMonitoring()
                }
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}
            
            CommandMenu("디바이스") {
                Button("새로고침") {
                    viewModel.startMonitoring()
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("모니터링 시작") {
                    viewModel.startMonitoring()
                }
                .disabled(viewModel.isMonitoring)
                
                Button("모니터링 중지") {
                    viewModel.stopMonitoring()
                }
                .disabled(!viewModel.isMonitoring)
            }
            
            CommandMenu("로그") {
                Button("로그 지우기") {
                    viewModel.clearLogs()
                }
                
                Button("통계 초기화") {
                    viewModel.resetStatistics()
                }
            }
        }
        
        // 메뉴바 아이템 (선택사항)
        #if os(macOS)
        MenuBarExtra("USBGuard", systemImage: "shield.fill") {
            MenuBarView()
                .environmentObject(viewModel)
        }
        #endif
    }
}

