import AccessorySetupKit
import SwiftUI

struct PairedAccessoryRow: View {
    let accessory: PairedAccessory
    let onRemove: () -> Void
    let onRename: (String) -> Void

    @State private var showRenameAlert = false
    @State private var newName = ""

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
        .swipeActions(edge: .leading) {
            Button {
                newName = accessory.displayName
                showRenameAlert = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .alert("Rename Accessory", isPresented: $showRenameAlert) {
            TextField("Name", text: $newName)
            Button("Rename") {
                let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    onRename(trimmed)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var stateLabel: String {
        switch accessory.state {
        case .authorized:
            "Authorized"
        case .unauthorized:
            "Unauthorized"
        case .awaitingAuthorization:
            "Awaiting Authorization"
        @unknown default:
            "Unknown"
        }
    }

    private var stateColor: Color {
        switch accessory.state {
        case .authorized:
            .green
        case .unauthorized, .awaitingAuthorization:
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
            onRemove: {},
            onRename: { _ in }
        )

        PairedAccessoryRow(
            accessory: PairedAccessory(displayName: "Temperature Sensor", state: .unauthorized),
            onRemove: {},
            onRename: { _ in }
        )
    }
}
