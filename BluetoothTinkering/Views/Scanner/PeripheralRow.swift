import SwiftUI

struct PeripheralRow: View {
    let peripheral: DiscoveredPeripheral

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(peripheral.displayName)
                    .font(.body)
                    .fontWeight(.bold)
                    .lineLimit(1)

                if !peripheral.advertisedServiceUUIDs.isEmpty {
                    Text("\(peripheral.advertisedServiceUUIDs.count) service\(peripheral.advertisedServiceUUIDs.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            SignalStrengthIndicator(rssi: peripheral.rssi)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    List {
        PeripheralRow(peripheral: DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: "Heart Rate Monitor",
            rssi: -55,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        ))
        PeripheralRow(peripheral: DiscoveredPeripheral(
            id: UUID(),
            peripheral: nil,
            name: nil,
            rssi: -90,
            advertisedServiceUUIDs: [],
            lastSeen: Date()
        ))
    }
}
