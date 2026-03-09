import AccessorySetupKit
import SwiftUI

struct PairedAccessoryRow: View {
    let accessory: PairedAccessory
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(accessory.displayName)
                    .font(.body)
                    .fontWeight(.bold)

                Text(stateLabel)
                    .font(.caption)
                    .foregroundStyle(stateColor)
            }

            Spacer()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var stateLabel: String {
        switch accessory.state {
        case .authorized:
            "Authorized"
        case .unauthorized:
            "Unauthorized"
        @unknown default:
            "Unknown"
        }
    }

    private var stateColor: Color {
        switch accessory.state {
        case .authorized:
            .green
        case .unauthorized:
            .red
        @unknown default:
            .secondary
        }
    }
}

// MARK: - Previews

#Preview {
    List {
        PairedAccessoryRow(
            accessory: PairedAccessory(displayName: "Heart Rate Monitor", state: .authorized),
            onRemove: {}
        )

        PairedAccessoryRow(
            accessory: PairedAccessory(displayName: "Temperature Sensor", state: .unauthorized),
            onRemove: {}
        )
    }
}
