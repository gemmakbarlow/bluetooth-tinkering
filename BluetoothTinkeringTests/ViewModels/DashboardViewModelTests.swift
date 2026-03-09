import XCTest
@testable import BluetoothTinkering

@MainActor
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
        sut.useMockData = false
        XCTAssertTrue(sut.showNoData)
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
