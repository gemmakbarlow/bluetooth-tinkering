import XCTest
@testable import BluetoothTinkering

@MainActor
final class AccessorySetupViewModelTests: XCTestCase {

    var sut: AccessorySetupViewModel!

    override func setUp() {
        sut = AccessorySetupViewModel()
    }

    func test_initialState_isNotActivated() {
        XCTAssertFalse(sut.isSessionActive)
    }

    func test_accessories_initiallyEmpty() {
        XCTAssertTrue(sut.accessories.isEmpty)
    }

    func test_isPickerPresented_initiallyFalse() {
        XCTAssertFalse(sut.isPickerPresented)
    }

    func test_handleAccessoryAdded_updatesAccessories() {
        sut.handleAccessoryAdded(displayName: "Test Device")

        XCTAssertEqual(sut.accessories.count, 1)
        XCTAssertEqual(sut.accessories.first?.displayName, "Test Device")
    }

    func test_handleAccessoryRemoved_updatesAccessories() {
        sut.handleAccessoryAdded(displayName: "Test Device")
        sut.handleAccessoryRemoved(displayName: "Test Device")

        XCTAssertTrue(sut.accessories.isEmpty)
    }

    func test_removeAccessory_removesById() {
        sut.handleAccessoryAdded(displayName: "Device A")
        sut.handleAccessoryAdded(displayName: "Device B")

        let deviceA = sut.accessories.first { $0.displayName == "Device A" }!
        sut.removeAccessory(deviceA)

        XCTAssertEqual(sut.accessories.count, 1)
        XCTAssertEqual(sut.accessories.first?.displayName, "Device B")
    }

    func test_error_setOnDiscoveryTimeout() {
        sut.setError(.discoveryTimeout)
        XCTAssertEqual(sut.error, .discoveryTimeout)
    }

    func test_error_setOnPickerAlreadyActive() {
        sut.setError(.pickerAlreadyActive)
        XCTAssertEqual(sut.error, .pickerAlreadyActive)
    }

    func test_error_isNilInitially() {
        XCTAssertNil(sut.error)
    }

    func test_renameAccessory_updatesDisplayName() {
        sut.handleAccessoryAdded(displayName: "Old Name")
        let accessory = sut.accessories.first!
        sut.renameAccessory(accessory, to: "New Name")

        XCTAssertEqual(sut.accessories.count, 1)
        XCTAssertEqual(sut.accessories.first?.displayName, "New Name")
    }
}
