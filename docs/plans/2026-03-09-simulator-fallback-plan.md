# Simulator Fallback Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Allow the app to run in demo mode on the iOS Simulator (where BLE is unsupported) by swapping to MockBluetoothManager with simulated responses.

**Architecture:** An `AppSettings` observable owns both managers and an `ApplicationMode` enum. When mode changes, ViewModels are re-created with the active manager. A floating gear button opens a Settings sheet. The BluetoothStateOverlay gains a "Use Demo Mode" button when state is `.unsupported`.

**Tech Stack:** SwiftUI, Swift Observation (@Observable), CoreBluetooth (via existing BluetoothManaging protocol)

---

### Task 1: Create ApplicationMode enum and AppSettings

**Files:**
- Create: `BluetoothTinkering/Models/ApplicationMode.swift`
- Create: `BluetoothTinkering/Settings/AppSettings.swift`
- Test: `BluetoothTinkeringTests/Settings/AppSettingsTests.swift`

**Step 1: Write the failing tests**

Create `BluetoothTinkeringTests/Settings/AppSettingsTests.swift`:

```swift
import XCTest
@testable import BluetoothTinkering

@MainActor
final class AppSettingsTests: XCTestCase {

    func test_defaultMode_isStandard() {
        let sut = AppSettings()
        XCTAssertEqual(sut.mode, .standard)
    }

    func test_activeManager_inStandardMode_isBluetoothManager() {
        let sut = AppSettings()
        XCTAssertTrue(sut.activeManager is BluetoothManager)
    }

    func test_activeManager_inDemoMode_isMockBluetoothManager() {
        let sut = AppSettings()
        sut.mode = .demo
        XCTAssertTrue(sut.activeManager is MockBluetoothManager)
    }

    func test_isDemoMode_reflectsMode() {
        let sut = AppSettings()
        XCTAssertFalse(sut.isDemoMode)
        sut.mode = .demo
        XCTAssertTrue(sut.isDemoMode)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E '(passed|failed|error:)'`
Expected: Build error — `AppSettings` and `ApplicationMode` don't exist yet.

**Step 3: Create ApplicationMode enum**

Create `BluetoothTinkering/Models/ApplicationMode.swift`:

```swift
import Foundation

enum ApplicationMode: Equatable {
    case standard
    case demo
}
```

**Step 4: Create AppSettings**

Create `BluetoothTinkering/Settings/AppSettings.swift`:

```swift
import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    private let realManager: BluetoothManager
    private let mockManager: MockBluetoothManager

    var mode: ApplicationMode = .standard

    var activeManager: any BluetoothManaging {
        switch mode {
        case .standard: realManager
        case .demo: mockManager
        }
    }

    var isDemoMode: Bool {
        mode == .demo
    }

    init() {
        self.realManager = BluetoothManager()
        self.mockManager = MockBluetoothManager()
    }
}
```

**Step 5: Run tests to verify they pass**

Run: `xcodebuild test -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E '(passed|failed|error:)'`
Expected: All 4 new tests PASS.

**Step 6: Commit**

```bash
git add BluetoothTinkering/Models/ApplicationMode.swift BluetoothTinkering/Settings/AppSettings.swift BluetoothTinkeringTests/Settings/AppSettingsTests.swift
git commit -m "feat: add ApplicationMode enum and AppSettings observable"
```

---

### Task 2: Enhance MockBluetoothManager with simulated scanning and connection

**Files:**
- Modify: `BluetoothTinkering/Bluetooth/MockBluetoothManager.swift`
- Test: `BluetoothTinkeringTests/Bluetooth/MockBluetoothManagerTests.swift`

**Step 1: Write the failing tests**

Create `BluetoothTinkeringTests/Bluetooth/MockBluetoothManagerTests.swift`:

```swift
import XCTest
import CoreBluetooth
@testable import BluetoothTinkering

@MainActor
final class MockBluetoothManagerTests: XCTestCase {

    var sut: MockBluetoothManager!

    override func setUp() {
        sut = MockBluetoothManager()
    }

    func test_startScanning_withSimulation_generatesPeripherals() {
        sut.simulatedScanningEnabled = true
        sut.startScanning()

        let expectation = expectation(description: "Peripherals discovered")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertGreaterThanOrEqual(self.sut.discoveredPeripherals.count, 3)
            XCTAssertTrue(self.sut.discoveredPeripherals.contains(where: { $0.name == "Heart Rate Monitor" }))
            XCTAssertTrue(self.sut.discoveredPeripherals.contains(where: { $0.name == "Temperature Sensor" }))
            XCTAssertTrue(self.sut.discoveredPeripherals.contains(where: { $0.name == nil }))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }

    func test_startScanning_withoutSimulation_doesNotGenerate() {
        sut.simulatedScanningEnabled = false
        sut.startScanning()
        XCTAssertTrue(sut.discoveredPeripherals.isEmpty)
    }

    func test_connect_withSimulation_simulatesConnection() {
        sut.simulatedScanningEnabled = true
        let peripheral = DiscoveredPeripheral.stub(name: "Test Device")
        sut.connect(to: peripheral)

        let expectation = expectation(description: "Connected")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(self.sut.connectionState, .connected)
            XCTAssertNotNil(self.sut.connectedPeripheral)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
    }

    func test_stopScanning_cancelsSimulatedDiscovery() {
        sut.simulatedScanningEnabled = true
        sut.startScanning()
        sut.stopScanning()
        XCTAssertFalse(sut.isScanning)
    }
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E '(passed|failed|error:)'`
Expected: Build error — `simulatedScanningEnabled` doesn't exist.

**Step 3: Enhance MockBluetoothManager**

Modify `BluetoothTinkering/Bluetooth/MockBluetoothManager.swift` — add simulated scanning and connection:

```swift
import CoreBluetooth
import Foundation
import Observation

@Observable
final class MockBluetoothManager: BluetoothManaging, @unchecked Sendable {
    var state: BluetoothState = .poweredOn
    var discoveredPeripherals: [DiscoveredPeripheral] = []
    var connectedPeripheral: DiscoveredPeripheral? = nil
    var connectionState: ConnectionState = .disconnected
    var discoveredServices: [DiscoveredService] = []
    var events: [BluetoothEvent] = []
    var isScanning: Bool = false

    /// When true, startScanning() auto-generates fake peripherals and connect() simulates success.
    var simulatedScanningEnabled: Bool = false

    private var simulatedScanTask: Task<Void, Never>?

    // Test hooks
    var onStartScanning: (() -> Void)?
    var onStopScanning: (() -> Void)?
    var onConnect: ((DiscoveredPeripheral) -> Void)?
    var onDisconnect: (() -> Void)?

    func startScanning() {
        isScanning = true
        onStartScanning?()

        if simulatedScanningEnabled {
            startSimulatedScan()
        }
    }

    func stopScanning() {
        isScanning = false
        simulatedScanTask?.cancel()
        simulatedScanTask = nil
        onStopScanning?()
    }

    func connect(to peripheral: DiscoveredPeripheral) {
        connectionState = .connecting
        onConnect?(peripheral)

        if simulatedScanningEnabled {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard connectionState == .connecting else { return }
                simulateConnection(peripheral)
            }
        }
    }

    func disconnect() {
        connectionState = .disconnecting
        onDisconnect?()

        if simulatedScanningEnabled {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                simulateDisconnection()
            }
        }
    }

    func discoverServices() {}
    func discoverCharacteristics(for service: DiscoveredService) {}
    func readValue(for characteristic: DiscoveredCharacteristic) {}
    func writeValue(_ data: Data, for characteristic: DiscoveredCharacteristic) {}
    func setNotify(_ enabled: Bool, for characteristic: DiscoveredCharacteristic) {}

    // MARK: - Simulated Scanning

    private func startSimulatedScan() {
        simulatedScanTask?.cancel()
        simulatedScanTask = Task { @MainActor in
            let fakePeripherals: [(String?, Int, [CBUUID])] = [
                ("Heart Rate Monitor", -45, [CBUUID(string: "180D")]),
                ("Temperature Sensor", -62, [CBUUID(string: "1809")]),
                ("Blood Pressure", -78, [CBUUID(string: "1810")]),
                (nil, -88, []),
            ]

            for (index, config) in fakePeripherals.enumerated() {
                try? await Task.sleep(for: .milliseconds(300 * (index + 1)))
                guard !Task.isCancelled, isScanning else { return }
                let peripheral = DiscoveredPeripheral(
                    id: UUID(),
                    peripheral: nil,
                    name: config.0,
                    rssi: config.1,
                    advertisedServiceUUIDs: config.2,
                    lastSeen: Date()
                )
                simulatePeripheralDiscovered(peripheral)
            }
        }
    }

    // MARK: - Test Helpers

    func simulatePeripheralDiscovered(_ peripheral: DiscoveredPeripheral) {
        if let index = discoveredPeripherals.firstIndex(where: { $0.id == peripheral.id }) {
            discoveredPeripherals[index].rssi = peripheral.rssi
            discoveredPeripherals[index].lastSeen = peripheral.lastSeen
        } else {
            discoveredPeripherals.append(peripheral)
        }
        events.append(BluetoothEvent(type: .scan, message: "Discovered \(peripheral.displayName)"))
    }

    func simulateConnection(_ peripheral: DiscoveredPeripheral) {
        connectedPeripheral = peripheral
        connectionState = .connected
        events.append(BluetoothEvent(type: .connection, message: "Connected to \(peripheral.displayName)"))
    }

    func simulateDisconnection() {
        let name = connectedPeripheral?.displayName ?? "device"
        connectedPeripheral = nil
        connectionState = .disconnected
        discoveredServices = []
        events.append(BluetoothEvent(type: .disconnection, message: "Disconnected from \(name)"))
    }

    func simulateStateChange(_ newState: BluetoothState) {
        state = newState
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E '(passed|failed|error:)'`
Expected: All 4 new tests + all existing tests PASS.

**Step 5: Commit**

```bash
git add BluetoothTinkering/Bluetooth/MockBluetoothManager.swift BluetoothTinkeringTests/Bluetooth/MockBluetoothManagerTests.swift
git commit -m "feat: add simulated scanning and connection to MockBluetoothManager"
```

---

### Task 3: Rewire composition root to use AppSettings

**Files:**
- Modify: `BluetoothTinkering/BluetoothTinkeringApp.swift`
- Modify: `BluetoothTinkering/ContentView.swift`

**Step 1: Update BluetoothTinkeringApp to use AppSettings**

Replace `BluetoothTinkering/BluetoothTinkeringApp.swift` with:

```swift
import SwiftUI

@main
struct BluetoothTinkeringApp: App {
    @State private var appSettings = AppSettings()
    @State private var scannerViewModel: ScannerViewModel
    @State private var deviceDetailViewModel: DeviceDetailViewModel
    @State private var accessorySetupViewModel: AccessorySetupViewModel
    @State private var backgroundViewModel: BackgroundViewModel
    @State private var dashboardViewModel: DashboardViewModel

    init() {
        let settings = AppSettings()
        _appSettings = State(initialValue: settings)
        let manager = settings.activeManager
        _scannerViewModel = State(initialValue: ScannerViewModel(manager: manager))
        _deviceDetailViewModel = State(initialValue: DeviceDetailViewModel(manager: manager))
        _accessorySetupViewModel = State(initialValue: AccessorySetupViewModel())
        _backgroundViewModel = State(initialValue: BackgroundViewModel(manager: manager))
        _dashboardViewModel = State(initialValue: DashboardViewModel(manager: manager))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(scannerViewModel)
                .environment(deviceDetailViewModel)
                .environment(accessorySetupViewModel)
                .environment(backgroundViewModel)
                .environment(dashboardViewModel)
                .environment(appSettings)
        }
    }
}
```

**Step 2: Update ContentView to use AppSettings**

Replace `BluetoothTinkering/ContentView.swift` with:

```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        TabView {
            Tab("Scanner", systemImage: "antenna.radiowaves.left.and.right") {
                ScannerView()
            }
            Tab("Setup", systemImage: "square.and.arrow.down.on.square") {
                AccessorySetupView()
            }
            Tab("Background", systemImage: "moon.fill") {
                BackgroundMonitorView()
            }
            Tab("Dashboard", systemImage: "chart.line.uptrend.xyaxis") {
                DashboardView()
            }
        }
        .tint(.blue)
        .overlay {
            if !appSettings.isDemoMode {
                BluetoothStateOverlay(state: appSettings.bluetoothState)
            }
        }
    }
}
```

Note: `appSettings.bluetoothState` is a new computed property. Add it to `AppSettings`:

```swift
var bluetoothState: BluetoothState {
    switch mode {
    case .standard: realManager.state
    case .demo: .poweredOn
    }
}
```

**Step 3: Build to verify compilation**

Run: `xcodebuild build -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`
Expected: Build succeeds.

**Step 4: Run all tests**

Run: `xcodebuild test -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E '(passed|failed|error:)'`
Expected: All existing tests still PASS.

**Step 5: Commit**

```bash
git add BluetoothTinkering/BluetoothTinkeringApp.swift BluetoothTinkering/ContentView.swift BluetoothTinkering/Settings/AppSettings.swift
git commit -m "refactor: rewire composition root to use AppSettings"
```

---

### Task 4: Add "Use Demo Mode" button to BluetoothStateOverlay

**Files:**
- Modify: `BluetoothTinkering/Views/Common/BluetoothStateOverlay.swift`

**Step 1: Update BluetoothStateOverlay**

The overlay needs access to `AppSettings` to set demo mode. Change it to accept an optional action callback (keeps the view testable without requiring `AppSettings` in previews):

```swift
import SwiftUI

struct BluetoothStateOverlay: View {
    let state: BluetoothState
    var onEnableDemoMode: (() -> Void)? = nil

    private var shouldShow: Bool {
        switch state {
        case .poweredOff, .unauthorized, .unsupported:
            return true
        case .unknown, .poweredOn:
            return false
        }
    }

    private var icon: String {
        switch state {
        case .poweredOff:
            return "bluetooth.slash"
        case .unauthorized:
            return "hand.raised.fill"
        case .unsupported:
            return "xmark.circle"
        case .unknown, .poweredOn:
            return ""
        }
    }

    private var title: String {
        switch state {
        case .poweredOff:
            return "Bluetooth is Off"
        case .unauthorized:
            return "Bluetooth Access Required"
        case .unsupported:
            return "Bluetooth Not Supported"
        case .unknown, .poweredOn:
            return ""
        }
    }

    private var guidance: String {
        switch state {
        case .poweredOff:
            return "Enable Bluetooth in Settings to discover nearby devices."
        case .unauthorized:
            return "This app needs Bluetooth permission. Go to Settings > Privacy & Security > Bluetooth to enable access."
        case .unsupported:
            return "This device does not support Bluetooth Low Energy."
        case .unknown, .poweredOn:
            return ""
        }
    }

    var body: some View {
        if shouldShow {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(guidance)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if state == .unsupported, let onEnableDemoMode {
                    Button("Use Demo Mode") {
                        onEnableDemoMode()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

#Preview("Unsupported with Demo") {
    BluetoothStateOverlay(state: .unsupported, onEnableDemoMode: {})
}

#Preview("Powered Off") {
    BluetoothStateOverlay(state: .poweredOff)
}

#Preview("Unauthorized") {
    BluetoothStateOverlay(state: .unauthorized)
}

#Preview("Powered On (Hidden)") {
    BluetoothStateOverlay(state: .poweredOn)
}
```

**Step 2: Wire up the callback in ContentView**

Update the overlay in `ContentView.swift`:

```swift
.overlay {
    if !appSettings.isDemoMode {
        BluetoothStateOverlay(state: appSettings.bluetoothState) {
            appSettings.mode = .demo
        }
    }
}
```

**Step 3: Build to verify**

Run: `xcodebuild build -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`
Expected: Build succeeds.

**Step 4: Commit**

```bash
git add BluetoothTinkering/Views/Common/BluetoothStateOverlay.swift BluetoothTinkering/ContentView.swift
git commit -m "feat: add 'Use Demo Mode' button to BluetoothStateOverlay"
```

---

### Task 5: Create Settings sheet and floating gear button

**Files:**
- Create: `BluetoothTinkering/Views/Settings/SettingsView.swift`
- Modify: `BluetoothTinkering/ContentView.swift`

**Step 1: Create SettingsView**

Create `BluetoothTinkering/Views/Settings/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var appSettings = appSettings

        NavigationStack {
            Form {
                Section {
                    // Future Consideration: If more ApplicationMode cases are added,
                    // change this Toggle to a Picker.
                    Toggle("Demo Mode", isOn: Binding(
                        get: { appSettings.isDemoMode },
                        set: { appSettings.mode = $0 ? .demo : .standard }
                    ))
                } footer: {
                    Text("Use simulated Bluetooth devices when real hardware is unavailable (e.g. iOS Simulator).")
                }

                Section("About") {
                    LabeledContent("App", value: "Bluetooth Tinkering")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let appSettings = AppSettings()

    SettingsView()
        .environment(appSettings)
}
```

**Step 2: Add floating gear button and demo mode banner to ContentView**

Update `BluetoothTinkering/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @Environment(AppSettings.self) private var appSettings
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView {
                Tab("Scanner", systemImage: "antenna.radiowaves.left.and.right") {
                    ScannerView()
                }
                Tab("Setup", systemImage: "square.and.arrow.down.on.square") {
                    AccessorySetupView()
                }
                Tab("Background", systemImage: "moon.fill") {
                    BackgroundMonitorView()
                }
                Tab("Dashboard", systemImage: "chart.line.uptrend.xyaxis") {
                    DashboardView()
                }
            }
            .tint(.blue)

            VStack(alignment: .trailing, spacing: 8) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.blue, in: Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 16)
                .padding(.top, 4)

                if appSettings.isDemoMode {
                    DemoModeBadge()
                        .padding(.trailing, 16)
                }
            }
        }
        .overlay {
            if !appSettings.isDemoMode {
                BluetoothStateOverlay(state: appSettings.bluetoothState) {
                    appSettings.mode = .demo
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
```

**Step 3: Create DemoModeBadge**

Create `BluetoothTinkering/Views/Common/DemoModeBadge.swift`:

```swift
import SwiftUI

struct DemoModeBadge: View {
    var body: some View {
        Text("Demo Mode")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.purple, in: Capsule())
    }
}

#Preview {
    DemoModeBadge()
}
```

**Step 4: Build to verify**

Run: `xcodebuild build -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`
Expected: Build succeeds.

**Step 5: Run all tests**

Run: `xcodebuild test -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E '(passed|failed|error:)'`
Expected: All tests PASS.

**Step 6: Commit**

```bash
git add BluetoothTinkering/Views/Settings/SettingsView.swift BluetoothTinkering/Views/Common/DemoModeBadge.swift BluetoothTinkering/ContentView.swift
git commit -m "feat: add Settings sheet with demo toggle and floating gear button"
```

---

### Task 6: Wire up mode switching to re-create ViewModels

**Files:**
- Modify: `BluetoothTinkering/BluetoothTinkeringApp.swift`
- Modify: `BluetoothTinkering/Settings/AppSettings.swift`

**Step 1: Add enableDemoMode/disableDemoMode to AppSettings**

These methods set `simulatedScanningEnabled` on the mock manager when entering demo mode:

Add to `BluetoothTinkering/Settings/AppSettings.swift`:

```swift
func enableDemoMode() {
    mockManager.simulatedScanningEnabled = true
    mode = .demo
}

func disableDemoMode() {
    mockManager.simulatedScanningEnabled = false
    mockManager.stopScanning()
    mockManager.discoveredPeripherals = []
    mockManager.simulateDisconnection()
    mode = .standard
}
```

**Step 2: Update BluetoothTinkeringApp to observe mode changes**

Replace `BluetoothTinkering/BluetoothTinkeringApp.swift` with:

```swift
import SwiftUI

@main
struct BluetoothTinkeringApp: App {
    @State private var appSettings = AppSettings()
    @State private var scannerViewModel: ScannerViewModel
    @State private var deviceDetailViewModel: DeviceDetailViewModel
    @State private var accessorySetupViewModel: AccessorySetupViewModel
    @State private var backgroundViewModel: BackgroundViewModel
    @State private var dashboardViewModel: DashboardViewModel

    init() {
        let settings = AppSettings()
        _appSettings = State(initialValue: settings)
        let manager = settings.activeManager
        _scannerViewModel = State(initialValue: ScannerViewModel(manager: manager))
        _deviceDetailViewModel = State(initialValue: DeviceDetailViewModel(manager: manager))
        _accessorySetupViewModel = State(initialValue: AccessorySetupViewModel())
        _backgroundViewModel = State(initialValue: BackgroundViewModel(manager: manager))
        _dashboardViewModel = State(initialValue: DashboardViewModel(manager: manager))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(scannerViewModel)
                .environment(deviceDetailViewModel)
                .environment(accessorySetupViewModel)
                .environment(backgroundViewModel)
                .environment(dashboardViewModel)
                .environment(appSettings)
                .onChange(of: appSettings.mode) { _, _ in
                    rebuildViewModels()
                }
        }
    }

    private func rebuildViewModels() {
        let manager = appSettings.activeManager
        scannerViewModel = ScannerViewModel(manager: manager)
        deviceDetailViewModel = DeviceDetailViewModel(manager: manager)
        backgroundViewModel = BackgroundViewModel(manager: manager)
        dashboardViewModel = DashboardViewModel(manager: manager)
    }
}
```

**Step 3: Update SettingsView to use enableDemoMode/disableDemoMode**

Update the Toggle in `SettingsView.swift`:

```swift
Toggle("Demo Mode", isOn: Binding(
    get: { appSettings.isDemoMode },
    set: { $0 ? appSettings.enableDemoMode() : appSettings.disableDemoMode() }
))
```

**Step 4: Update BluetoothStateOverlay callback in ContentView**

Update the overlay callback:

```swift
BluetoothStateOverlay(state: appSettings.bluetoothState) {
    appSettings.enableDemoMode()
}
```

**Step 5: Build and run all tests**

Run: `xcodebuild test -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E '(passed|failed|error:)'`
Expected: All tests PASS.

**Step 6: Add tests for enableDemoMode/disableDemoMode**

Add to `BluetoothTinkeringTests/Settings/AppSettingsTests.swift`:

```swift
func test_enableDemoMode_setsMode() {
    let sut = AppSettings()
    sut.enableDemoMode()
    XCTAssertEqual(sut.mode, .demo)
}

func test_disableDemoMode_setsMode() {
    let sut = AppSettings()
    sut.enableDemoMode()
    sut.disableDemoMode()
    XCTAssertEqual(sut.mode, .standard)
}
```

**Step 7: Run tests**

Run: `xcodebuild test -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E '(passed|failed|error:)'`
Expected: All tests PASS.

**Step 8: Commit**

```bash
git add BluetoothTinkering/BluetoothTinkeringApp.swift BluetoothTinkering/Settings/AppSettings.swift BluetoothTinkering/Views/Settings/SettingsView.swift BluetoothTinkering/ContentView.swift BluetoothTinkeringTests/Settings/AppSettingsTests.swift
git commit -m "feat: wire up mode switching to re-create ViewModels with active manager"
```

---

### Task 7: Final integration test and push

**Step 1: Build**

Run: `xcodebuild build -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | tail -5`
Expected: Clean build.

**Step 2: Run all tests**

Run: `xcodebuild test -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -quiet 2>&1 | grep -E '(passed|failed|error:)'`
Expected: All tests PASS.

**Step 3: Push**

```bash
git push
```
