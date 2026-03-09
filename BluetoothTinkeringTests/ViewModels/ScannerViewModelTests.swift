import XCTest
@testable import BluetoothTinkering

@MainActor
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
            peripheral: nil,
            name: name,
            rssi: rssi,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        )
    }
}
