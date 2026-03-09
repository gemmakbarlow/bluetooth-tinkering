import SwiftUI

struct EventRow: View {
    let event: BluetoothEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.message)
                    .font(.body)
                    .lineLimit(2)

                Text(event.timestamp, format: .dateTime.hour().minute().second())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var iconName: String {
        switch event.type {
        case .scan:
            "antenna.radiowaves.left.and.right"
        case .connection:
            "link"
        case .disconnection:
            "xmark.circle"
        case .notification:
            "bell"
        case .error:
            "exclamationmark.triangle"
        case .background:
            "moon.fill"
        }
    }

    private var iconColor: Color {
        switch event.type {
        case .scan:
            .blue
        case .connection:
            .green
        case .disconnection:
            .red
        case .notification:
            .orange
        case .error:
            .red
        case .background:
            .purple
        }
    }
}

// MARK: - Previews

#Preview {
    List {
        EventRow(event: BluetoothEvent(type: .scan, message: "Discovered Heart Rate Monitor"))
        EventRow(event: BluetoothEvent(type: .connection, message: "Connected to Heart Rate Monitor"))
        EventRow(event: BluetoothEvent(type: .notification, message: "Received heart rate: 72 bpm"))
        EventRow(event: BluetoothEvent(type: .error, message: "Connection timeout"))
        EventRow(event: BluetoothEvent(type: .disconnection, message: "Disconnected from Heart Rate Monitor"))
        EventRow(event: BluetoothEvent(type: .background, message: "App entered background"))
    }
}
