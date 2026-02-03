# usbGuard
macOS USB 보안 앱

# USBGuard - macOS USB/외부 디바이스 제어 앱

## 프로젝트 구조

```text
USBGuard/
├── USBGuard/                          # Main App (SwiftUI)
│   ├── App/
│   │   ├── USBGuardApp.swift         # 앱 진입점
│   │   └── AppDelegate.swift         # 시스템 이벤트 처리
│   ├── Views/
│   │   ├── DashboardView.swift       # 메인 대시보드
│   │   ├── DeviceListView.swift      # 연결된 디바이스 목록
│   │   ├── PolicyView.swift          # 정책 설정
│   │   └── LogView.swift             # 접근 로그
│   ├── ViewModels/
│   │   ├── DeviceMonitorViewModel.swift
│   │   └── PolicyViewModel.swift
│   ├── Models/
│   │   ├── USBDevice.swift           # 디바이스 모델
│   │   ├── DevicePolicy.swift        # 정책 모델
│   │   └── AccessLog.swift           # 로그 모델
│   └── Services/
│       ├── IOKitService.swift        # IOKit 래퍼
│       └── XPCClient.swift           # Extension 통신
│
├── USBGuardExtension/                 # System Extension
│   ├── ExtensionMain.swift           # Extension 진입점
│   ├── IOKitMonitor.swift            # USB 모니터링
│   ├── DeviceController.swift        # 디바이스 제어
│   └── XPCServer.swift               # Main App과 통신
│
└── Shared/
    ├── XPCProtocol.swift             # 공유 프로토콜
    └── Constants.swift               # 상수 정의
```

## 주요 기능

### Phase 1: 기본 모니터링 ✅
- IOKit을 사용한 USB 디바이스 감지
- 실시간 연결/해제 이벤트
- 디바이스 정보 수집 (이름, 제조사, 용량, 시리얼)

### Phase 2: 정책 엔진 🎯
- 화이트리스트/블랙리스트
- 디바이스 타입별 정책
- 시간대별 접근 제어

### Phase 3: 제어 및 차단 🔒
- 승인되지 않은 디바이스 마운트 방지
- 읽기 전용 모드 강제
- 관리자 승인 워크플로우

### Phase 4: 로깅 및 알림 📊
- 모든 디바이스 접근 로깅
- 의심스러운 활동 알림
- 통계 및 리포트

## 기술 스택
- SwiftUI (UI)
- IOKit (USB 디바이스 모니터링)
- System Extension (백그라운드 모니터링)
- XPC (프로세스 간 통신)
- EndpointSecurity (선택적, 파일 접근 감시)
- SQLite (로그 저장)
