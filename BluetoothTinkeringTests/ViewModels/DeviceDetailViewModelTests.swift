import XCTest
@testable import BluetoothTinkering

@MainActor
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

    // MARK: - Helpers

    private func makePeripheral(name: String?) -> DiscoveredPeripheral {
        DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: name,
            rssi: -50,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        )
    }
}
