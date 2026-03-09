import AccessorySetupKit
import CoreBluetooth
import Foundation
import Observation
import UIKit

struct PairedAccessory: Identifiable {
    let id: UUID
    let displayName: String
    let state: ASAccessory.AccessoryState

    init(from accessory: ASAccessory) {
        self.id = UUID()
        self.displayName = accessory.displayName
        self.state = accessory.state
    }

    // Test convenience initializer
    init(id: UUID = UUID(), displayName: String, state: ASAccessory.AccessoryState = .authorized) {
        self.id = id
        self.displayName = displayName
        self.state = state
    }
}

enum AccessorySetupError: LocalizedError, Equatable {
    case activationFailed(String)
    case pickerCancelled
    case discoveryTimeout
    case pickerAlreadyActive
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .activationFailed(let msg): return "Session activation failed: \(msg)"
        case .pickerCancelled: return "Accessory picker was cancelled."
        case .discoveryTimeout: return "No matching accessories found. Make sure your device is nearby and in pairing mode."
        case .pickerAlreadyActive: return "The accessory picker is already active."
        case .unknown(let msg): return msg
        }
    }
}

@MainActor
@Observable
final class AccessorySetupViewModel {
    private var session: ASAccessorySession?

    var accessories: [PairedAccessory] = []
    var isSessionActive: Bool = false
    var isPickerPresented: Bool = false
    var error: AccessorySetupError?

    init() {}

    func activateSession() {
        let session = ASAccessorySession()
        self.session = session

        session.activate(on: .main) { [weak self] event in
            Task { @MainActor in
                self?.handleEvent(event)
            }
        }
        isSessionActive = true
    }

    func showPicker() {
        guard let session else { return }
        isPickerPresented = true
        error = nil

        let descriptor = ASDiscoveryDescriptor()
        descriptor.bluetoothServiceUUID = CBUUID(string: "180D")

        let item = ASPickerDisplayItem(
            name: "BLE Accessory",
            productImage: UIImage(systemName: "sensor.tag.radiowaves.forward.fill")!,
            descriptor: descriptor
        )

        session.showPicker(for: [item]) { [weak self] error in
            Task { @MainActor in
                self?.isPickerPresented = false
                if let error {
                    self?.handleSessionError(error)
                }
            }
        }
    }

    func removeAccessory(_ accessory: PairedAccessory) {
        accessories.removeAll { $0.id == accessory.id }
    }

    func renameAccessory(_ accessory: PairedAccessory, to newName: String) {
        guard let index = accessories.firstIndex(where: { $0.id == accessory.id }) else { return }
        accessories[index] = PairedAccessory(id: accessory.id, displayName: newName, state: accessory.state)
    }

    // MARK: - Internal for testing

    func handleAccessoryAdded(displayName: String) {
        let paired = PairedAccessory(displayName: displayName)
        accessories.append(paired)
    }

    func handleAccessoryRemoved(displayName: String) {
        accessories.removeAll { $0.displayName == displayName }
    }

    func setError(_ error: AccessorySetupError) {
        self.error = error
    }

    private func handleSessionError(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == "ASAccessorySessionErrorDomain" {
            switch nsError.code {
            case 700:
                self.error = .discoveryTimeout
            case 800:
                self.error = .pickerAlreadyActive
            default:
                self.error = .unknown(error.localizedDescription)
            }
        } else {
            self.error = .unknown(error.localizedDescription)
        }
    }

    private func handleEvent(_ event: ASAccessoryEvent) {
        switch event.eventType {
        case .activated:
            isSessionActive = true
            if let session {
                accessories = session.accessories.map { PairedAccessory(from: $0) }
            }
        case .accessoryAdded:
            if let accessory = event.accessory {
                let paired = PairedAccessory(from: accessory)
                accessories.append(paired)
            }
        case .accessoryRemoved:
            if let accessory = event.accessory {
                accessories.removeAll { $0.displayName == accessory.displayName }
            }
        case .accessoryChanged:
            if let session {
                accessories = session.accessories.map { PairedAccessory(from: $0) }
            }
        case .pickerDidDismiss:
            isPickerPresented = false
        default:
            break
        }
    }
}
