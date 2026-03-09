import XCTest
@testable import BluetoothTinkering

@MainActor
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
        let old = BluetoothEvent(type: .scan, message: "Old", timestamp: Date(timeIntervalSince1970: 1000))
        let new = BluetoothEvent(type: .scan, message: "New", timestamp: Date(timeIntervalSince1970: 2000))
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

    func test_isMonitoring_startsScanning() {
        sut.isMonitoring = true
        XCTAssertTrue(mock.isScanning)
    }

    func test_isMonitoring_stopsScanning() {
        sut.isMonitoring = true
        sut.isMonitoring = false
        XCTAssertFalse(mock.isScanning)
    }

    func test_hasConnectedDevice_reflectsManager() {
        XCTAssertFalse(sut.hasConnectedDevice)
    }
}
