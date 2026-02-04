//
//  PolicyView.swift
//  USBGuard
//
//  Created by wooseob on 2/4/26.
//  디바이스 접근 정책 생성 및 관리

import SwiftUI

struct PolicyView: View {
    @State private var policies: [DevicePolicy] = []
    @State private var showingAddPolicy = false
    @State private var selectedPolicy: DevicePolicy?
    
    var body: some View {
        NavigationSplitView {
            // 왼쪽: 정책 목록
            policyList
        } detail: {
            // 오른쪽: 정책 상세/편집
            if let policy = selectedPolicy {
                PolicyDetailView(policy: binding(for: policy))
            } else {
                placeholderView
            }
        }
        .navigationTitle("⚙️ 정책 관리")
        .onAppear {
            loadPolicies()
        }
        .sheet(isPresented: $showingAddPolicy) {
            AddPolicyView { newPolicy in
                PolicyEngine.shared.addPolicy(newPolicy)
                loadPolicies()
            }
        }
    }
    
    // MARK: - Policy List
    private var policyList: some View {
        List(selection: $selectedPolicy) {
            ForEach(policies) { policy in
                PolicyRow(policy: policy)
                    .tag(policy)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deletePolicy(policy)
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                        
                        Button {
                            togglePolicy(policy)
                        } label: {
                            Label(policy.enabled ? "비활성화" : "활성화",
                                  systemImage: policy.enabled ? "pause.circle" : "play.circle")
                        }
                        .tint(policy.enabled ? .orange : .green)
                    }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddPolicy = true }) {
                    Label("정책 추가", systemImage: "plus")
                }
            }
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("정책을 선택하세요")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Functions
    private func binding(for policy: DevicePolicy) -> Binding<DevicePolicy> {
        guard let index = policies.firstIndex(where: { $0.id == policy.id }) else {
            fatalError("Policy not found")
        }
        return $policies[index]
    }
    
    private func loadPolicies() {
        policies = PolicyEngine.shared.getAllPolicies()
    }
    
    private func togglePolicy(_ policy: DevicePolicy) {
        var updated = policy
        updated.enabled.toggle()
        PolicyEngine.shared.updatePolicy(updated)
        loadPolicies()
    }
    
    private func deletePolicy(_ policy: DevicePolicy) {
        PolicyEngine.shared.removePolicy(policy.id)
        loadPolicies()
        if selectedPolicy?.id == policy.id {
            selectedPolicy = nil
        }
    }
}

// MARK: - Policy Row
struct PolicyRow: View {
    let policy: DevicePolicy
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: policy.action.icon)
                .foregroundColor(colorForAction(policy.action))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(policy.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label(policy.ruleType.rawValue, systemImage: ruleTypeIcon(policy.ruleType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !policy.conditions.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(policy.conditions.count)개 조건")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(policy.enabled))
                .labelsHidden()
        }
        .opacity(policy.enabled ? 1.0 : 0.5)
    }
    
    private func ruleTypeIcon(_ type: RuleType) -> String {
        switch type {
        case .whitelist: return "checkmark.circle"
        case .blacklist: return "xmark.circle"
        }
    }
    
    private func colorForAction(_ action: PolicyAction) -> Color {
        switch action.color {
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
}

// MARK: - Policy Detail View
struct PolicyDetailView: View {
    @Binding var policy: DevicePolicy
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                VStack(alignment: .leading, spacing: 8) {
                    Text(policy.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label(policy.ruleType.rawValue, systemImage: "shield")
                        Text("•")
                        Label(policy.action.rawValue, systemImage: policy.action.icon)
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(12)
                
                // 설명
                VStack(alignment: .leading, spacing: 8) {
                    Text("정책 설명")
                        .font(.headline)
                    Text(policy.ruleType.description)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(12)
                
                // 조건
                VStack(alignment: .leading, spacing: 12) {
                    Text("적용 조건")
                        .font(.headline)
                    
                    if policy.conditions.isEmpty {
                        Text("모든 디바이스에 적용")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(Array(policy.conditions.enumerated()), id: \.offset) { _, condition in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(condition.description)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(12)
                
                // 메타데이터
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("생성일")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(policy.createdDate.formatted())
                    }
                    
                    HStack {
                        Text("최종 수정")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(policy.modifiedDate.formatted())
                    }
                }
                .font(.caption)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(12)
            }
            .padding()
        }
    }
}

// MARK: - Add Policy View
struct AddPolicyView: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (DevicePolicy) -> Void
    
    @State private var name = ""
    @State private var ruleType: RuleType = .whitelist
    @State private var action: PolicyAction = .allow
    @State private var selectedDeviceClass: DeviceClass?
    @State private var vendorName = ""
    @State private var useTimeRange = false
    @State private var startTime = "09:00"
    @State private var endTime = "18:00"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("정책 이름", text: $name)
                    
                    Picker("규칙 타입", selection: $ruleType) {
                        ForEach(RuleType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Picker("액션", selection: $action) {
                        ForEach(PolicyAction.allCases, id: \.self) { action in
                            Label(action.rawValue, systemImage: action.icon).tag(action)
                        }
                    }
                }
                
                Section("조건") {
                    Picker("디바이스 타입", selection: $selectedDeviceClass) {
                        Text("모든 타입").tag(nil as DeviceClass?)
                        ForEach(DeviceClass.allCases, id: \.self) { deviceClass in
                            Text(deviceClass.rawValue).tag(deviceClass as DeviceClass?)
                        }
                    }
                    
                    TextField("제조사 이름 (선택사항)", text: $vendorName)
                    
                    Toggle("시간대 제한", isOn: $useTimeRange)
                    
                    if useTimeRange {
                        HStack {
                            Text("시작 시간")
                            Spacer()
                            TextField("09:00", text: $startTime)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("종료 시간")
                            Spacer()
                            TextField("18:00", text: $endTime)
                                .frame(width: 80)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("새 정책 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        savePolicy()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func savePolicy() {
        var conditions: [PolicyCondition] = []
        
        if let deviceClass = selectedDeviceClass {
            conditions.append(.deviceClass(deviceClass))
        }
        
        if !vendorName.isEmpty {
            conditions.append(.vendorName(vendorName))
        }
        
        if useTimeRange {
            conditions.append(.timeRange(start: startTime, end: endTime))
        }
        
        let policy = DevicePolicy(
            name: name,
            ruleType: ruleType,
            action: action,
            conditions: conditions
        )
        
        onSave(policy)
        dismiss()
    }
}

#Preview {
    PolicyView()
        .frame(width: 900, height: 600)
}
