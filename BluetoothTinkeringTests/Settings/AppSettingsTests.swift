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
