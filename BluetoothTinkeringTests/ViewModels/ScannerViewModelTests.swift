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
        let named = DiscoveredPeripheral.stub(name: "Heart Rate", rssi: -50)
        let unnamed = DiscoveredPeripheral.stub(name: nil, rssi: -60)
        mock.discoveredPeripherals = [named, unnamed]

        sut.hideUnnamed = true

        XCTAssertEqual(sut.filteredPeripherals.count, 1)
        XCTAssertEqual(sut.filteredPeripherals.first?.name, "Heart Rate")
    }

    func test_filteredPeripherals_showsAllWhenFilterDisabled() {
        let named = DiscoveredPeripheral.stub(name: "Heart Rate", rssi: -50)
        let unnamed = DiscoveredPeripheral.stub(name: nil, rssi: -60)
        mock.discoveredPeripherals = [named, unnamed]

        sut.hideUnnamed = false

        XCTAssertEqual(sut.filteredPeripherals.count, 2)
    }

    // MARK: - Sorting

    func test_sortBySignalStrength_sortsDescendingRSSI() {
        let weak = DiscoveredPeripheral.stub(name: "A", rssi: -90)
        let strong = DiscoveredPeripheral.stub(name: "B", rssi: -40)
        mock.discoveredPeripherals = [weak, strong]

        sut.sortOption = .signalStrength

        XCTAssertEqual(sut.filteredPeripherals.first?.name, "B")
    }

    func test_sortByName_sortsAlphabetically() {
        let b = DiscoveredPeripheral.stub(name: "Bravo", rssi: -50)
        let a = DiscoveredPeripheral.stub(name: "Alpha", rssi: -90)
        mock.discoveredPeripherals = [b, a]

        sut.sortOption = .name

        XCTAssertEqual(sut.filteredPeripherals.first?.name, "Alpha")
    }

}
