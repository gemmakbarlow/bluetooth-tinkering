import SwiftUI

struct CharacteristicRow: View {
    let characteristic: DiscoveredCharacteristic
    let onRead: () -> Void
    let onWrite: (String) -> Void
    let onToggleNotify: () -> Void

    @State private var writeText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(characteristic.displayName)
                .font(.subheadline)
                .fontWeight(.medium)

            if let value = characteristic.valueString {
                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            HStack(spacing: 12) {
                if characteristic.canRead {
                    Button {
                        onRead()
                    } label: {
                        Label("Read", systemImage: "arrow.down.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }

                if characteristic.canNotify {
                    Toggle(isOn: Binding(
                        get: { characteristic.isNotifying },
                        set: { _ in onToggleNotify() }
                    )) {
                        Label("Notify", systemImage: "bell")
                            .font(.caption)
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.bordered)
                    .tint(characteristic.isNotifying ? .blue : .gray)
                }
            }

            if characteristic.canWrite {
                HStack {
                    TextField("Value to write...", text: $writeText)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)

                    Button {
                        guard !writeText.isEmpty else { return }
                        onWrite(writeText)
                        writeText = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    .disabled(writeText.isEmpty)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
