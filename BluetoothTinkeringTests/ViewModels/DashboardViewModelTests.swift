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
        let peripheral = DiscoveredPeripheral.stub(name: "HR Monitor")
        mock.simulateConnection(peripheral)
        sut.useMockData = false
        XCTAssertFalse(sut.isSimulated)
    }

    func test_isSimulated_trueWhenMockModeForced() {
        let peripheral = DiscoveredPeripheral.stub(name: "HR Monitor")
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
        let peripheral = DiscoveredPeripheral.stub(name: "HR Monitor")
        mock.simulateConnection(peripheral)
        XCTAssertTrue(sut.shouldPromptForLiveData)
    }

    func test_noData_shownWhenNoRecentValues() {
        sut.useMockData = false
        XCTAssertTrue(sut.showNoData)
    }

    func test_addLiveDataPoint_clearsStaleFlag() {
        sut.isDataStale = true
        sut.addLiveDataPoint(72.0)
        XCTAssertFalse(sut.isDataStale)
    }

    func test_addLiveDataPoint_updatesLastReceivedDate() {
        XCTAssertNil(sut.lastReceivedDate)
        sut.addLiveDataPoint(72.0)
        XCTAssertNotNil(sut.lastReceivedDate)
    }

    func test_switchToLiveData_clearsDataPoints() {
        sut.startMockData()
        sut.dataPoints.append(DataPoint(timestamp: Date(), value: 50))
        sut.switchToLiveData()
        XCTAssertTrue(sut.dataPoints.isEmpty)
        XCTAssertFalse(sut.useMockData)
        sut.stopStaleDataCheck()
    }

}
