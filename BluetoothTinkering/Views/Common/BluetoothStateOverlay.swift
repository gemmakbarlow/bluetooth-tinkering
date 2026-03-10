import SwiftUI

struct BluetoothStateOverlay: View {
    let state: BluetoothState
    var onEnableDemoMode: (() -> Void)? = nil

    private var shouldShow: Bool {
        switch state {
        case .poweredOff, .unauthorized, .unsupported:
            return true
        case .unknown, .poweredOn:
            return false
        }
    }

    private var icon: String {
        switch state {
        case .poweredOff: return "bluetooth.slash"
        case .unauthorized: return "hand.raised.fill"
        case .unsupported: return "xmark.circle"
        case .unknown, .poweredOn: return ""
        }
    }

    private var title: String {
        switch state {
        case .poweredOff: return "Bluetooth is Off"
        case .unauthorized: return "Bluetooth Access Required"
        case .unsupported: return "Bluetooth Not Supported"
        case .unknown, .poweredOn: return ""
        }
    }

    private var guidance: String {
        switch state {
        case .poweredOff:
            return "Enable Bluetooth in Settings to discover nearby devices."
        case .unauthorized:
            return "This app needs Bluetooth permission. Go to Settings > Privacy & Security > Bluetooth to enable access."
        case .unsupported:
            return "This device does not support Bluetooth Low Energy."
        case .unknown, .poweredOn:
            return ""
        }
    }

    var body: some View {
        if shouldShow {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(guidance)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if state == .unsupported, let onEnableDemoMode {
                    Button("Use Demo Mode") {
                        onEnableDemoMode()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

#Preview("Unsupported with Demo") {
    BluetoothStateOverlay(state: .unsupported, onEnableDemoMode: {})
}

#Preview("Powered Off") {
    BluetoothStateOverlay(state: .poweredOff)
}

#Preview("Unauthorized") {
    BluetoothStateOverlay(state: .unauthorized)
}

#Preview("Powered On (Hidden)") {
    BluetoothStateOverlay(state: .poweredOn)
}
