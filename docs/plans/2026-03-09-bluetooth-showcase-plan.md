# Bluetooth Showcase App — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a 3-tab iOS app showcasing BLE capabilities (scanning, device interaction, background monitoring, live dashboard) using CoreBluetooth, SwiftUI, and the Swift Observation framework.

**Architecture:** Single `BluetoothManager` (@Observable) wrapping CBCentralManager, injected into per-feature ViewModels via constructor injection. Views receive ViewModels from SwiftUI @Environment. MockBluetoothManager for tests and previews.

**Tech Stack:** Swift, SwiftUI, CoreBluetooth, iOS 18+, @Observable macro, XCTest

---

## Task 1: Xcode Project Scaffold

**Files:**
- Create: `BluetoothTinkering/BluetoothTinkeringApp.swift`
- Create: `BluetoothTinkering/ContentView.swift`
- Create: `BluetoothTinkering/Info.plist`
- Create: `BluetoothTinkering/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `BluetoothTinkeringTests/` (test target)

**Step 1: Create Xcode project**

Use Xcode CLI or create manually:
- Product name: `BluetoothTinkering`
- Bundle ID: `com.gemmakbarlow.bluetooth-tinkering`
- Interface: SwiftUI
- Language: Swift
- Minimum deployment: iOS 18.0
- Include Tests: Yes (Unit Tests only)

**Step 2: Configure Info.plist**

Add required keys:
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to discover and connect to nearby BLE devices.</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

**Step 3: Set accent color to blue**

In `Assets.xcassets/AccentColor.colorset/Contents.json`, set the accent color to system blue (`0, 122, 255`).

**Step 4: Verify project builds**

Run: `xcodebuild -project BluetoothTinkering.xcodeproj -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: scaffold Xcode project with Bluetooth entitlements"
```

---

## Task 2: Models

**Files:**
- Create: `BluetoothTinkering/Models/DiscoveredPeripheral.swift`
- Create: `BluetoothTinkering/Models/DiscoveredService.swift`
- Create: `BluetoothTinkering/Models/DiscoveredCharacteristic.swift`
- Create: `BluetoothTinkering/Models/BluetoothEvent.swift`

**Step 1: Create DiscoveredPeripheral**

```swift
import CoreBluetooth
import Foundation

struct DiscoveredPeripheral: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    var name: String?
    var rssi: Int
    var advertisedServiceUUIDs: [CBUUID]
    var lastSeen: Date

    var displayName: String {
        name ?? "Unknown Device"
    }

    var isNamed: Bool {
        name != nil
    }
}
```

**Step 2: Create DiscoveredService**

```swift
import CoreBluetooth
import Foundation

struct DiscoveredService: Identifiable {
    let id: String
    let service: CBService
    var characteristics: [DiscoveredCharacteristic]

    init(service: CBService) {
        self.id = service.uuid.uuidString
        self.service = service
        self.characteristics = []
    }

    var displayName: String {
        service.uuid.description
    }
}
```

**Step 3: Create DiscoveredCharacteristic**

```swift
import CoreBluetooth
import Foundation

struct DiscoveredCharacteristic: Identifiable {
    let id: String
    let characteristic: CBCharacteristic
    var lastValue: Data?
    var isNotifying: Bool

    init(characteristic: CBCharacteristic) {
        self.id = characteristic.uuid.uuidString
        self.characteristic = characteristic
        self.lastValue = characteristic.value
        self.isNotifying = characteristic.isNotifying
    }

    var canRead: Bool {
        characteristic.properties.contains(.read)
    }

    var canWrite: Bool {
        characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse)
    }

    var canNotify: Bool {
        characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate)
    }

    var displayName: String {
        characteristic.uuid.description
    }

    var valueString: String? {
        guard let data = lastValue else { return nil }
        return String(data: data, encoding: .utf8) ?? data.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
}
```

**Step 4: Create BluetoothEvent**

```swift
import Foundation

struct BluetoothEvent: Identifiable {
    let id: UUID
    let timestamp: Date
    let type: EventType
    let message: String

    init(type: EventType, message: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.message = message
    }

    enum EventType: String {
        case scan
        case connection
        case disconnection
        case notification
        case error
        case background
    }
}
```

**Step 5: Verify project builds**

Run: `xcodebuild -project BluetoothTinkering.xcodeproj -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add BluetoothTinkering/Models/
git commit -m "feat: add model structs for peripherals, services, characteristics, events"
```

---

## Task 3: BluetoothManaging Protocol

**Files:**
- Create: `BluetoothTinkering/Bluetooth/BluetoothManaging.swift`

**Step 1: Define the protocol**

```swift
import CoreBluetooth
import Foundation

enum BluetoothState: Equatable {
    case unknown
    case poweredOff
    case poweredOn
    case unauthorized
    case unsupported
}

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

protocol BluetoothManaging: AnyObject, Observable {
    var state: BluetoothState { get }
    var discoveredPeripherals: [DiscoveredPeripheral] { get }
    var connectedPeripheral: DiscoveredPeripheral? { get }
    var connectionState: ConnectionState { get }
    var discoveredServices: [DiscoveredService] { get }
    var events: [BluetoothEvent] { get }
    var isScanning: Bool { get }

    func startScanning()
    func stopScanning()
    func connect(to peripheral: DiscoveredPeripheral)
    func disconnect()
    func discoverServices()
    func discoverCharacteristics(for service: DiscoveredService)
    func readValue(for characteristic: DiscoveredCharacteristic)
    func writeValue(_ data: Data, for characteristic: DiscoveredCharacteristic)
    func setNotify(_ enabled: Bool, for characteristic: DiscoveredCharacteristic)
}
```

**Step 2: Verify project builds**

Run: `xcodebuild build` (same destination as before)
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add BluetoothTinkering/Bluetooth/
git commit -m "feat: add BluetoothManaging protocol"
```

---

## Task 4: MockBluetoothManager

**Files:**
- Create: `BluetoothTinkering/Bluetooth/MockBluetoothManager.swift`

**Step 1: Implement MockBluetoothManager**

```swift
import CoreBluetooth
import Foundation
import Observation

@Observable
final class MockBluetoothManager: BluetoothManaging {
    var state: BluetoothState = .poweredOn
    var discoveredPeripherals: [DiscoveredPeripheral] = []
    var connectedPeripheral: DiscoveredPeripheral? = nil
    var connectionState: ConnectionState = .disconnected
    var discoveredServices: [DiscoveredService] = []
    var events: [BluetoothEvent] = []
    var isScanning: Bool = false

    // Test hooks
    var onStartScanning: (() -> Void)?
    var onStopScanning: (() -> Void)?
    var onConnect: ((DiscoveredPeripheral) -> Void)?
    var onDisconnect: (() -> Void)?

    func startScanning() {
        isScanning = true
        onStartScanning?()
    }

    func stopScanning() {
        isScanning = false
        onStopScanning?()
    }

    func connect(to peripheral: DiscoveredPeripheral) {
        connectionState = .connecting
        onConnect?(peripheral)
    }

    func disconnect() {
        connectionState = .disconnecting
        onDisconnect?()
    }

    func discoverServices() {}
    func discoverCharacteristics(for service: DiscoveredService) {}
    func readValue(for characteristic: DiscoveredCharacteristic) {}
    func writeValue(_ data: Data, for characteristic: DiscoveredCharacteristic) {}
    func setNotify(_ enabled: Bool, for characteristic: DiscoveredCharacteristic) {}

    // Helpers for tests
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

**Step 2: Verify project builds**

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add BluetoothTinkering/Bluetooth/MockBluetoothManager.swift
git commit -m "feat: add MockBluetoothManager for testing and previews"
```

---

## Task 5: ScannerViewModel + Tests

**Files:**
- Create: `BluetoothTinkering/ViewModels/ScannerViewModel.swift`
- Create: `BluetoothTinkeringTests/ViewModels/ScannerViewModelTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import BluetoothTinkering

final class ScannerViewModelTests: XCTestCase {

    var mock: MockBluetoothManager!
    var sut: ScannerViewModel!

    override func setUp() {
        mock = MockBluetoothManager()
        sut = ScannerViewModel(manager: mock)
    }

    // MARK: - Scanning

    func test_startScanning_setsManagerScanning() {
        sut.startScanning()
        XCTAssertTrue(mock.isScanning)
    }

    func test_stopScanning_stopsManagerScanning() {
        sut.startScanning()
        sut.stopScanning()
        XCTAssertFalse(mock.isScanning)
    }

    // MARK: - Filtering

    func test_filteredPeripherals_hidesUnnamedWhenFilterEnabled() {
        let named = makePeripheral(name: "Heart Rate", rssi: -50)
        let unnamed = makePeripheral(name: nil, rssi: -60)
        mock.discoveredPeripherals = [named, unnamed]

        sut.hideUnnamed = true

        XCTAssertEqual(sut.filteredPeripherals.count, 1)
        XCTAssertEqual(sut.filteredPeripherals.first?.name, "Heart Rate")
    }

    func test_filteredPeripherals_showsAllWhenFilterDisabled() {
        let named = makePeripheral(name: "Heart Rate", rssi: -50)
        let unnamed = makePeripheral(name: nil, rssi: -60)
        mock.discoveredPeripherals = [named, unnamed]

        sut.hideUnnamed = false

        XCTAssertEqual(sut.filteredPeripherals.count, 2)
    }

    // MARK: - Sorting

    func test_sortBySignalStrength_sortsDescendingRSSI() {
        let weak = makePeripheral(name: "A", rssi: -90)
        let strong = makePeripheral(name: "B", rssi: -40)
        mock.discoveredPeripherals = [weak, strong]

        sut.sortOption = .signalStrength

        XCTAssertEqual(sut.filteredPeripherals.first?.name, "B")
    }

    func test_sortByName_sortsAlphabetically() {
        let b = makePeripheral(name: "Bravo", rssi: -50)
        let a = makePeripheral(name: "Alpha", rssi: -90)
        mock.discoveredPeripherals = [b, a]

        sut.sortOption = .name

        XCTAssertEqual(sut.filteredPeripherals.first?.name, "Alpha")
    }

    // MARK: - Helpers

    private func makePeripheral(name: String?, rssi: Int) -> DiscoveredPeripheral {
        DiscoveredPeripheral(
            id: UUID(),
            peripheral: CBPeripheral(), // Will need a mock or workaround
            name: name,
            rssi: rssi,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        )
    }
}
```

> **Note:** `CBPeripheral` cannot be directly instantiated. We will need to adjust the `DiscoveredPeripheral` model to hold the peripheral as an optional or use a protocol wrapper. Decide during implementation — the key is that tests don't need a real `CBPeripheral`. Consider making `peripheral` optional or storing just the `CBPeripheral` identifier separately.

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project BluetoothTinkering.xcodeproj -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: FAIL — `ScannerViewModel` not found

**Step 3: Implement ScannerViewModel**

```swift
import Foundation
import Observation

enum SortOption {
    case signalStrength
    case name
}

@Observable
final class ScannerViewModel {
    private let manager: any BluetoothManaging

    var hideUnnamed: Bool = false
    var sortOption: SortOption = .signalStrength

    var bluetoothState: BluetoothState {
        manager.state
    }

    var isScanning: Bool {
        manager.isScanning
    }

    var filteredPeripherals: [DiscoveredPeripheral] {
        var result = manager.discoveredPeripherals

        if hideUnnamed {
            result = result.filter { $0.isNamed }
        }

        switch sortOption {
        case .signalStrength:
            result.sort { $0.rssi > $1.rssi }
        case .name:
            result.sort { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
        }

        return result
    }

    init(manager: any BluetoothManaging) {
        self.manager = manager
    }

    func startScanning() {
        manager.startScanning()
    }

    func stopScanning() {
        manager.stopScanning()
    }
}
```

**Step 4: Run tests to verify they pass**

Expected: PASS

**Step 5: Commit**

```bash
git add BluetoothTinkering/ViewModels/ScannerViewModel.swift BluetoothTinkeringTests/
git commit -m "feat: add ScannerViewModel with filtering and sorting, plus tests"
```

---

## Task 6: DeviceDetailViewModel + Tests

**Files:**
- Create: `BluetoothTinkering/ViewModels/DeviceDetailViewModel.swift`
- Create: `BluetoothTinkeringTests/ViewModels/DeviceDetailViewModelTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import BluetoothTinkering

final class DeviceDetailViewModelTests: XCTestCase {

    var mock: MockBluetoothManager!
    var sut: DeviceDetailViewModel!

    override func setUp() {
        mock = MockBluetoothManager()
        sut = DeviceDetailViewModel(manager: mock)
    }

    func test_connect_setsConnectingState() {
        let peripheral = makePeripheral(name: "Device")
        sut.connect(to: peripheral)
        XCTAssertEqual(mock.connectionState, .connecting)
    }

    func test_disconnect_setsDisconnectingState() {
        sut.disconnect()
        XCTAssertEqual(mock.connectionState, .disconnecting)
    }

    func test_connectionState_reflectsManager() {
        mock.connectionState = .connected
        XCTAssertEqual(sut.connectionState, .connected)
    }

    func test_isConnecting_preventsDuplicateConnect() {
        mock.connectionState = .connecting
        XCTAssertTrue(sut.isConnecting)
    }

    func test_services_reflectsManager() {
        XCTAssertTrue(sut.services.isEmpty)
    }

    func test_connectionTimeout_triggersAfterDelay() async {
        let peripheral = makePeripheral(name: "Slow Device")
        sut.connect(to: peripheral)

        // Simulate timeout by waiting — implementation should use Task with timeout
        // This test verifies the timeout resets state to disconnected
    }
}
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement DeviceDetailViewModel**

```swift
import Foundation
import Observation

@Observable
final class DeviceDetailViewModel {
    private let manager: any BluetoothManaging
    private var connectionTimeoutTask: Task<Void, Never>?

    var connectionState: ConnectionState {
        manager.connectionState
    }

    var isConnecting: Bool {
        manager.connectionState == .connecting
    }

    var services: [DiscoveredService] {
        manager.discoveredServices
    }

    var connectedPeripheral: DiscoveredPeripheral? {
        manager.connectedPeripheral
    }

    var error: String?

    init(manager: any BluetoothManaging) {
        self.manager = manager
    }

    func connect(to peripheral: DiscoveredPeripheral) {
        guard !isConnecting else { return }
        error = nil
        manager.connect(to: peripheral)
        startConnectionTimeout()
    }

    func disconnect() {
        connectionTimeoutTask?.cancel()
        manager.disconnect()
    }

    func discoverServices() {
        manager.discoverServices()
    }

    func discoverCharacteristics(for service: DiscoveredService) {
        manager.discoverCharacteristics(for: service)
    }

    func readValue(for characteristic: DiscoveredCharacteristic) {
        manager.readValue(for: characteristic)
    }

    func writeValue(_ string: String, for characteristic: DiscoveredCharacteristic) {
        guard let data = string.data(using: .utf8) else { return }
        manager.writeValue(data, for: characteristic)
    }

    func toggleNotify(for characteristic: DiscoveredCharacteristic) {
        manager.setNotify(!characteristic.isNotifying, for: characteristic)
    }

    private func startConnectionTimeout() {
        connectionTimeoutTask?.cancel()
        connectionTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(10))
            if !Task.isCancelled && connectionState == .connecting {
                manager.disconnect()
                error = "Connection timed out. Please try again."
            }
        }
    }
}
```

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add BluetoothTinkering/ViewModels/DeviceDetailViewModel.swift BluetoothTinkeringTests/
git commit -m "feat: add DeviceDetailViewModel with connection management and timeout"
```

---

## Task 7: BackgroundViewModel + Tests

**Files:**
- Create: `BluetoothTinkering/ViewModels/BackgroundViewModel.swift`
- Create: `BluetoothTinkeringTests/ViewModels/BackgroundViewModelTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import BluetoothTinkering

final class BackgroundViewModelTests: XCTestCase {

    var mock: MockBluetoothManager!
    var sut: BackgroundViewModel!

    override func setUp() {
        mock = MockBluetoothManager()
        sut = BackgroundViewModel(manager: mock)
    }

    func test_events_reflectsManagerEvents() {
        mock.events.append(BluetoothEvent(type: .connection, message: "Connected"))
        XCTAssertEqual(sut.events.count, 1)
    }

    func test_events_areSortedNewestFirst() {
        let old = BluetoothEvent(type: .scan, message: "Old")
        let new = BluetoothEvent(type: .scan, message: "New")
        mock.events = [old, new]

        XCTAssertEqual(sut.events.first?.message, "New")
    }

    func test_events_cappedAt100() {
        for i in 0..<150 {
            mock.events.append(BluetoothEvent(type: .scan, message: "Event \(i)"))
        }
        XCTAssertEqual(sut.events.count, 100)
    }

    func test_isMonitoring_togglesState() {
        sut.isMonitoring = true
        XCTAssertTrue(sut.isMonitoring)

        sut.isMonitoring = false
        XCTAssertFalse(sut.isMonitoring)
    }

    func test_hasConnectedDevice_reflectsManager() {
        XCTAssertFalse(sut.hasConnectedDevice)
    }
}
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement BackgroundViewModel**

```swift
import Foundation
import Observation

@Observable
final class BackgroundViewModel {
    private let manager: any BluetoothManaging

    var isMonitoring: Bool = false

    var events: [BluetoothEvent] {
        Array(manager.events.sorted { $0.timestamp > $1.timestamp }.prefix(100))
    }

    var hasConnectedDevice: Bool {
        manager.connectedPeripheral != nil
    }

    init(manager: any BluetoothManaging) {
        self.manager = manager
    }
}
```

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add BluetoothTinkering/ViewModels/BackgroundViewModel.swift BluetoothTinkeringTests/
git commit -m "feat: add BackgroundViewModel with event log and monitoring toggle"
```

---

## Task 8: DashboardViewModel + Tests

**Files:**
- Create: `BluetoothTinkering/ViewModels/DashboardViewModel.swift`
- Create: `BluetoothTinkeringTests/ViewModels/DashboardViewModelTests.swift`

**Step 1: Write failing tests**

```swift
import XCTest
@testable import BluetoothTinkering

final class DashboardViewModelTests: XCTestCase {

    var mock: MockBluetoothManager!
    var sut: DashboardViewModel!

    override func setUp() {
        mock = MockBluetoothManager()
        sut = DashboardViewModel(manager: mock)
    }

    func test_isSimulated_trueWhenNoDeviceConnected() {
        mock.connectedPeripheral = nil
        XCTAssertTrue(sut.isSimulated)
    }

    func test_isSimulated_falseWhenDeviceConnectedAndLiveMode() {
        let peripheral = makePeripheral(name: "HR Monitor")
        mock.simulateConnection(peripheral)
        sut.useMockData = false
        XCTAssertFalse(sut.isSimulated)
    }

    func test_isSimulated_trueWhenMockModeForced() {
        let peripheral = makePeripheral(name: "HR Monitor")
        mock.simulateConnection(peripheral)
        sut.useMockData = true
        XCTAssertTrue(sut.isSimulated)
    }

    func test_dataPoints_populatedInMockMode() {
        sut.startMockData()
        // Allow mock timer to fire
        let expectation = expectation(description: "Mock data generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertFalse(self.sut.dataPoints.isEmpty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }

    func test_shouldPromptForLiveData_whenDeviceConnectsDuringMock() {
        sut.startMockData()
        let peripheral = makePeripheral(name: "HR Monitor")
        mock.simulateConnection(peripheral)
        XCTAssertTrue(sut.shouldPromptForLiveData)
    }

    func test_noData_shownWhenNoRecentValues() {
        // No data points and not in mock mode
        sut.useMockData = false
        XCTAssertTrue(sut.showNoData)
    }
}
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement DashboardViewModel**

```swift
import Foundation
import Observation

struct DataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

@Observable
final class DashboardViewModel {
    private let manager: any BluetoothManaging
    private var mockTimer: Timer?
    private var noDataTimer: Timer?
    private let noDataTimeout: TimeInterval = 10

    var dataPoints: [DataPoint] = []
    var useMockData: Bool = true
    var lastReceivedDate: Date?

    var isSimulated: Bool {
        useMockData || manager.connectedPeripheral == nil
    }

    var currentValue: Double? {
        dataPoints.last?.value
    }

    var shouldPromptForLiveData: Bool {
        manager.connectedPeripheral != nil && useMockData
    }

    var showNoData: Bool {
        dataPoints.isEmpty && !isSimulated
    }

    init(manager: any BluetoothManaging) {
        self.manager = manager
    }

    func startMockData() {
        useMockData = true
        mockTimer?.invalidate()
        mockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.addMockDataPoint()
        }
    }

    func stopMockData() {
        mockTimer?.invalidate()
        mockTimer = nil
    }

    func switchToLiveData() {
        stopMockData()
        useMockData = false
        dataPoints = []
    }

    func addLiveDataPoint(_ value: Double) {
        lastReceivedDate = Date()
        let point = DataPoint(timestamp: Date(), value: value)
        dataPoints.append(point)
        trimDataPoints()
    }

    private func addMockDataPoint() {
        // Simulate a heart rate between 60-100 bpm
        let base = 75.0
        let variation = Double.random(in: -15...15)
        let point = DataPoint(timestamp: Date(), value: base + variation)
        dataPoints.append(point)
        trimDataPoints()
    }

    private func trimDataPoints() {
        if dataPoints.count > 60 {
            dataPoints.removeFirst(dataPoints.count - 60)
        }
    }
}
```

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add BluetoothTinkering/ViewModels/DashboardViewModel.swift BluetoothTinkeringTests/
git commit -m "feat: add DashboardViewModel with mock data and live data support"
```

---

## Task 9: BluetoothManager (Real Implementation)

**Files:**
- Create: `BluetoothTinkering/Bluetooth/BluetoothManager.swift`
- Create: `BluetoothTinkeringTests/Bluetooth/BluetoothManagerTests.swift`

**Step 1: Write failing tests**

> **Note:** BluetoothManager wraps CBCentralManager which requires a real Bluetooth stack. Tests focus on state mapping and peripheral list management using the manager's public interface where possible. Some behaviors (delegate callbacks) are tested by calling internal handler methods.

```swift
import XCTest
@testable import BluetoothTinkering

final class BluetoothManagerTests: XCTestCase {

    func test_initialState_isUnknown() {
        let sut = BluetoothManager()
        XCTAssertEqual(sut.state, .unknown)
    }

    func test_scanAutoStop_afterTimeout() async {
        let sut = BluetoothManager(scanTimeout: 0.5)
        // Would need powered-on state; test the timeout mechanism
        // This may need to be an integration test on device
    }

    func test_peripheralDeduplication_updatesRSSI() {
        let sut = BluetoothManager()
        let id = UUID()
        sut.handleDiscovery(id: id, name: "Test", rssi: -80, serviceUUIDs: [])
        sut.handleDiscovery(id: id, name: "Test", rssi: -50, serviceUUIDs: [])

        XCTAssertEqual(sut.discoveredPeripherals.count, 1)
        XCTAssertEqual(sut.discoveredPeripherals.first?.rssi, -50)
    }
}
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement BluetoothManager**

```swift
import CoreBluetooth
import Foundation
import Observation

@Observable
final class BluetoothManager: NSObject, BluetoothManaging {
    var state: BluetoothState = .unknown
    var discoveredPeripherals: [DiscoveredPeripheral] = []
    var connectedPeripheral: DiscoveredPeripheral? = nil
    var connectionState: ConnectionState = .disconnected
    var discoveredServices: [DiscoveredService] = []
    var events: [BluetoothEvent] = []
    var isScanning: Bool = false

    private var centralManager: CBCentralManager!
    private var scanTimeoutTask: Task<Void, Never>?
    private let scanTimeout: TimeInterval

    init(scanTimeout: TimeInterval = 30) {
        self.scanTimeout = scanTimeout
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionRestoreIdentifierKey: "com.gemmakbarlow.bluetooth-tinkering.central"
        ])
    }

    func startScanning() {
        guard state == .poweredOn else { return }
        discoveredPeripherals = []
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        isScanning = true
        events.append(BluetoothEvent(type: .scan, message: "Started scanning"))
        startScanTimeout()
    }

    func stopScanning() {
        scanTimeoutTask?.cancel()
        centralManager.stopScan()
        isScanning = false
        events.append(BluetoothEvent(type: .scan, message: "Stopped scanning"))
    }

    func connect(to peripheral: DiscoveredPeripheral) {
        connectionState = .connecting
        centralManager.connect(peripheral.peripheral, options: nil)
    }

    func disconnect() {
        if let peripheral = connectedPeripheral?.peripheral {
            connectionState = .disconnecting
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func discoverServices() {
        connectedPeripheral?.peripheral.discoverServices(nil)
    }

    func discoverCharacteristics(for service: DiscoveredService) {
        connectedPeripheral?.peripheral.discoverCharacteristics(nil, for: service.service)
    }

    func readValue(for characteristic: DiscoveredCharacteristic) {
        connectedPeripheral?.peripheral.readValue(for: characteristic.characteristic)
    }

    func writeValue(_ data: Data, for characteristic: DiscoveredCharacteristic) {
        let type: CBCharacteristicWriteType = characteristic.characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        connectedPeripheral?.peripheral.writeValue(data, for: characteristic.characteristic, type: type)
    }

    func setNotify(_ enabled: Bool, for characteristic: DiscoveredCharacteristic) {
        connectedPeripheral?.peripheral.setNotifyValue(enabled, for: characteristic.characteristic)
    }

    // MARK: - Internal for testing

    func handleDiscovery(id: UUID, name: String?, rssi: Int, serviceUUIDs: [CBUUID]) {
        if let index = discoveredPeripherals.firstIndex(where: { $0.id == id }) {
            discoveredPeripherals[index].rssi = rssi
            discoveredPeripherals[index].lastSeen = Date()
        } else {
            // For real discoveries, peripheral is set via delegate; this is for test support
            let peripheral = DiscoveredPeripheral(
                id: id,
                peripheral: nil, // Adjusted model needed
                name: name,
                rssi: rssi,
                advertisedServiceUUIDs: serviceUUIDs,
                lastSeen: Date()
            )
            discoveredPeripherals.append(peripheral)
        }
    }

    private func startScanTimeout() {
        scanTimeoutTask?.cancel()
        scanTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(scanTimeout))
            if !Task.isCancelled && isScanning {
                stopScanning()
            }
        }
    }

    private func mapState(_ cbState: CBManagerState) -> BluetoothState {
        switch cbState {
        case .poweredOn: return .poweredOn
        case .poweredOff: return .poweredOff
        case .unauthorized: return .unauthorized
        case .unsupported: return .unsupported
        default: return .unknown
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = mapState(central.state)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []

        if let index = discoveredPeripherals.firstIndex(where: { $0.id == peripheral.identifier }) {
            discoveredPeripherals[index].rssi = RSSI.intValue
            discoveredPeripherals[index].lastSeen = Date()
            if let name = name { discoveredPeripherals[index].name = name }
        } else {
            let discovered = DiscoveredPeripheral(
                id: peripheral.identifier,
                peripheral: peripheral,
                name: name,
                rssi: RSSI.intValue,
                advertisedServiceUUIDs: serviceUUIDs,
                lastSeen: Date()
            )
            discoveredPeripherals.append(discovered)
            events.append(BluetoothEvent(type: .scan, message: "Discovered \(discovered.displayName)"))
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let index = discoveredPeripherals.firstIndex(where: { $0.id == peripheral.identifier }) {
            connectedPeripheral = discoveredPeripherals[index]
        }
        connectionState = .connected
        peripheral.delegate = self
        events.append(BluetoothEvent(type: .connection, message: "Connected to \(peripheral.name ?? "device")"))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let name = connectedPeripheral?.displayName ?? "device"
        connectedPeripheral = nil
        connectionState = .disconnected
        discoveredServices = []
        events.append(BluetoothEvent(type: .disconnection, message: "Disconnected from \(name)"))
        if let error = error {
            events.append(BluetoothEvent(type: .error, message: "Disconnect error: \(error.localizedDescription)"))
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectionState = .disconnected
        events.append(BluetoothEvent(type: .error, message: "Failed to connect: \(error?.localizedDescription ?? "unknown")"))
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        events.append(BluetoothEvent(type: .background, message: "State restored from background"))
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        discoveredServices = services.map { DiscoveredService(service: $0) }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        if let index = discoveredServices.firstIndex(where: { $0.id == service.uuid.uuidString }) {
            discoveredServices[index].characteristics = characteristics.map { DiscoveredCharacteristic(characteristic: $0) }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        for serviceIndex in discoveredServices.indices {
            if let charIndex = discoveredServices[serviceIndex].characteristics.firstIndex(where: { $0.id == characteristic.uuid.uuidString }) {
                discoveredServices[serviceIndex].characteristics[charIndex].lastValue = characteristic.value
            }
        }
        if characteristic.isNotifying {
            events.append(BluetoothEvent(type: .notification, message: "Value updated for \(characteristic.uuid)"))
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        for serviceIndex in discoveredServices.indices {
            if let charIndex = discoveredServices[serviceIndex].characteristics.firstIndex(where: { $0.id == characteristic.uuid.uuidString }) {
                discoveredServices[serviceIndex].characteristics[charIndex].isNotifying = characteristic.isNotifying
            }
        }
    }
}
```

> **Note:** The `DiscoveredPeripheral.peripheral` field needs to become `CBPeripheral?` to support both real usage and test helper methods. Adjust the model in Task 2 accordingly during implementation.

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add BluetoothTinkering/Bluetooth/BluetoothManager.swift BluetoothTinkeringTests/
git commit -m "feat: add BluetoothManager wrapping CBCentralManager with delegate handling"
```

---

## Task 10: Scanner Views

**Files:**
- Create: `BluetoothTinkering/Views/Scanner/ScannerView.swift`
- Create: `BluetoothTinkering/Views/Scanner/PeripheralRow.swift`
- Create: `BluetoothTinkering/Views/Scanner/SignalStrengthIndicator.swift`

**Step 1: Create SignalStrengthIndicator**

A small view showing 1-4 bars based on RSSI value:
- Excellent: > -50 (4 bars)
- Good: -50 to -70 (3 bars)
- Fair: -70 to -85 (2 bars)
- Weak: < -85 (1 bar)

Blue-tinted bars.

**Step 2: Create PeripheralRow**

Row showing: device name, signal strength indicator, advertised service count, chevron for navigation.

**Step 3: Create ScannerView**

- NavigationStack with list of `filteredPeripherals`
- Toolbar toggle for `hideUnnamed`
- Toolbar picker for sort option
- Pull-to-refresh calling `startScanning()`
- Empty state with "No devices found" message
- Navigation link to DeviceDetailView on tap

**Step 4: Verify builds and previews work**

**Step 5: Commit**

```bash
git add BluetoothTinkering/Views/Scanner/
git commit -m "feat: add Scanner views with filtering, sorting, and signal indicator"
```

---

## Task 11: Device Detail Views

**Files:**
- Create: `BluetoothTinkering/Views/DeviceDetail/DeviceDetailView.swift`
- Create: `BluetoothTinkering/Views/DeviceDetail/ServiceSection.swift`
- Create: `BluetoothTinkering/Views/DeviceDetail/CharacteristicRow.swift`

**Step 1: Create CharacteristicRow**

Shows: characteristic UUID, current value, action buttons (Read/Write/Notify) based on properties. Write shows a text field. Notify shows a toggle.

**Step 2: Create ServiceSection**

DisclosureGroup for each service, containing CharacteristicRows.

**Step 3: Create DeviceDetailView**

- Connect/disconnect button (disabled while connecting)
- Connection state indicator
- Error display for timeouts
- List of ServiceSections when connected
- "Discovering services..." progress when just connected

**Step 4: Verify builds**

**Step 5: Commit**

```bash
git add BluetoothTinkering/Views/DeviceDetail/
git commit -m "feat: add Device Detail views with service/characteristic browsing"
```

---

## Task 12: Background Monitor Views

**Files:**
- Create: `BluetoothTinkering/Views/Background/BackgroundMonitorView.swift`
- Create: `BluetoothTinkering/Views/Background/EventRow.swift`
- Create: `BluetoothTinkering/Views/Background/BackgroundInfoSection.swift`

**Step 1: Create EventRow**

Shows: timestamp, event type icon (color-coded), message. Event types use SF Symbols:
- scan: `antenna.radiowaves.left.and.right`
- connection: `link`
- disconnection: `link.badge.xmark` (or similar, SF Symbol availability may vary, use `xmark.circle` as fallback)
- notification: `bell`
- error: `exclamationmark.triangle`
- background: `moon.fill`

**Step 2: Create BackgroundInfoSection**

Static info explaining: what background modes are enabled, how state restoration works, tips for testing background BLE.

**Step 3: Create BackgroundMonitorView**

- Toggle for monitoring (disabled when no device connected)
- Info section at top
- Scrollable event log, newest first
- Empty state when no events

**Step 4: Verify builds**

**Step 5: Commit**

```bash
git add BluetoothTinkering/Views/Background/
git commit -m "feat: add Background Monitor views with event log and info section"
```

---

## Task 13: Dashboard Views

**Files:**
- Create: `BluetoothTinkering/Views/Dashboard/DashboardView.swift`
- Create: `BluetoothTinkering/Views/Dashboard/SimpleLineChart.swift`
- Create: `BluetoothTinkering/Views/Dashboard/SimulatedDataBadge.swift`

**Step 1: Create SimulatedDataBadge**

Purple pill/capsule with "Simulated Data" text. Prominent, clearly visible.

```swift
struct SimulatedDataBadge: View {
    var body: some View {
        Text("Simulated Data")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.purple, in: Capsule())
    }
}
```

**Step 2: Create SimpleLineChart**

Use Swift Charts (`Chart` with `LineMark`) to display `dataPoints` over time. Blue line, blue gradient fill below.

**Step 3: Create DashboardView**

- Large current value display at top
- SimulatedDataBadge shown when `isSimulated`
- Line chart of recent values
- "No Data" state when `showNoData`
- Alert prompting to switch to live data when `shouldPromptForLiveData`
- Auto-starts mock data on appear when no device connected

**Step 4: Verify builds**

**Step 5: Commit**

```bash
git add BluetoothTinkering/Views/Dashboard/
git commit -m "feat: add Dashboard views with line chart, mock data, and simulated badge"
```

---

## Task 14: Bluetooth State Overlay

**Files:**
- Create: `BluetoothTinkering/Views/Common/BluetoothStateOverlay.swift`

**Step 1: Create overlay view**

A full-screen overlay that appears when Bluetooth is off, unauthorized, or unsupported. Shows:
- Relevant SF Symbol icon
- Clear message about what's wrong
- Guidance on how to fix (e.g. "Enable Bluetooth in Settings")

Applied as a `.overlay()` on the main ContentView, driven by `BluetoothManager.state`.

**Step 2: Verify builds**

**Step 3: Commit**

```bash
git add BluetoothTinkering/Views/Common/
git commit -m "feat: add Bluetooth state overlay for off/unauthorized/unsupported states"
```

---

## Task 15: App Composition Root & Tab Navigation

**Files:**
- Modify: `BluetoothTinkering/BluetoothTinkeringApp.swift`
- Modify: `BluetoothTinkering/ContentView.swift`

**Step 1: Update BluetoothTinkeringApp**

Create all dependencies at the composition root:

```swift
import SwiftUI

@main
struct BluetoothTinkeringApp: App {
    @State private var bluetoothManager = BluetoothManager()
    @State private var scannerViewModel: ScannerViewModel
    @State private var deviceDetailViewModel: DeviceDetailViewModel
    @State private var backgroundViewModel: BackgroundViewModel
    @State private var dashboardViewModel: DashboardViewModel

    init() {
        let manager = BluetoothManager()
        _bluetoothManager = State(initialValue: manager)
        _scannerViewModel = State(initialValue: ScannerViewModel(manager: manager))
        _deviceDetailViewModel = State(initialValue: DeviceDetailViewModel(manager: manager))
        _backgroundViewModel = State(initialValue: BackgroundViewModel(manager: manager))
        _dashboardViewModel = State(initialValue: DashboardViewModel(manager: manager))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(scannerViewModel)
                .environment(deviceDetailViewModel)
                .environment(backgroundViewModel)
                .environment(dashboardViewModel)
                .environment(bluetoothManager)
        }
    }
}
```

**Step 2: Update ContentView with TabView**

```swift
import SwiftUI

struct ContentView: View {
    @Environment(BluetoothManager.self) private var bluetoothManager

    var body: some View {
        TabView {
            Tab("Scanner", systemImage: "antenna.radiowaves.left.and.right") {
                ScannerView()
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
            BluetoothStateOverlay(state: bluetoothManager.state)
        }
    }
}
```

**Step 3: Verify full app builds**

Run: `xcodebuild build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add BluetoothTinkering/BluetoothTinkeringApp.swift BluetoothTinkering/ContentView.swift
git commit -m "feat: wire up composition root and tab navigation"
```

---

## Task 16: Final Integration & Polish

**Step 1: Run all tests**

Run: `xcodebuild test -project BluetoothTinkering.xcodeproj -scheme BluetoothTinkering -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: All tests PASS

**Step 2: Fix any compilation issues or test failures**

Iterate until clean.

**Step 3: Build and run on simulator**

Verify:
- App launches with 3 tabs
- Scanner tab shows empty state (no BLE on simulator)
- Bluetooth state overlay appears (simulator has no Bluetooth)
- Dashboard mock data works with purple "Simulated Data" badge
- Background monitor shows event log

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: final integration and polish pass"
```

---

## Summary

| Task | Description | Dependencies |
|------|-------------|-------------|
| 1 | Xcode project scaffold | None |
| 2 | Models | Task 1 |
| 3 | BluetoothManaging protocol | Task 2 |
| 4 | MockBluetoothManager | Task 3 |
| 5 | ScannerViewModel + tests | Task 4 |
| 6 | DeviceDetailViewModel + tests | Task 4 |
| 7 | BackgroundViewModel + tests | Task 4 |
| 8 | DashboardViewModel + tests | Task 4 |
| 9 | BluetoothManager (real) | Task 3 |
| 10 | Scanner views | Task 5 |
| 11 | Device Detail views | Task 6 |
| 12 | Background Monitor views | Task 7 |
| 13 | Dashboard views | Task 8 |
| 14 | Bluetooth state overlay | Task 3 |
| 15 | App composition root & tabs | Tasks 10-14 |
| 16 | Final integration & polish | Task 15 |

Tasks 5-8 can be parallelized. Tasks 10-14 can be parallelized.
