import XCTest
@testable import BluetoothTinkering

final class BluetoothManagerTests: XCTestCase {

    func test_initialState_isUnknown() {
        let sut = BluetoothManager()
        XCTAssertEqual(sut.state, .unknown)
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
