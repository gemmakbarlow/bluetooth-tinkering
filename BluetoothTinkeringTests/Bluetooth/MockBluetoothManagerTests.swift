import XCTest
import CoreBluetooth
@testable import BluetoothTinkering

@MainActor
final class MockBluetoothManagerTests: XCTestCase {

    var sut: MockBluetoothManager!

    override func setUp() async throws {
        sut = MockBluetoothManager()
    }

    override func tearDown() {
        sut.stopScanning()
        sut = nil
    }

    func test_startScanning_withSimulation_generatesPeripherals() async throws {
        sut.simulatedScanningEnabled = true
        sut.startScanning()

        // Wait long enough for all 4 peripherals
        // Cumulative delays: 300, 900, 1800, 3000ms
        try await Task.sleep(for: .milliseconds(4000))

        XCTAssertGreaterThanOrEqual(sut.discoveredPeripherals.count, 3)
        XCTAssertTrue(sut.discoveredPeripherals.contains(where: { $0.name == "Heart Rate Monitor" }))
        XCTAssertTrue(sut.discoveredPeripherals.contains(where: { $0.name == "Temperature Sensor" }))
        XCTAssertTrue(sut.discoveredPeripherals.contains(where: { $0.name == nil }))
    }

    func test_startScanning_withoutSimulation_doesNotGenerate() {
        sut.simulatedScanningEnabled = false
        sut.startScanning()
        XCTAssertTrue(sut.discoveredPeripherals.isEmpty)
    }

    func test_connect_withSimulation_simulatesConnection() async throws {
        sut.simulatedScanningEnabled = true
        let peripheral = DiscoveredPeripheral.stub(name: "Test Device")
        sut.connect(to: peripheral)

        try await Task.sleep(for: .milliseconds(1000))

        XCTAssertEqual(sut.connectionState, .connected)
        XCTAssertNotNil(sut.connectedPeripheral)
    }

    func test_stopScanning_cancelsSimulatedDiscovery() {
        sut.simulatedScanningEnabled = true
        sut.startScanning()
        sut.stopScanning()
        XCTAssertFalse(sut.isScanning)
    }
}
