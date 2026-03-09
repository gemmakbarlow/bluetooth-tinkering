import SwiftUI

struct AccessorySetupInfoSection: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup("AccessorySetupKit vs CoreBluetooth", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                infoItem(
                    icon: "sparkles",
                    title: "AccessorySetupKit (iOS 18+)",
                    detail: "One-tap pairing via a system picker. Privacy-first — no broad Bluetooth permission needed. Paired accessories are centrally managed in Settings."
                )

                infoItem(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Traditional CoreBluetooth",
                    detail: "Manual scanning and discovery. Requires Bluetooth permission upfront. Your app handles the full discovery, connection, and reconnection lifecycle."
                )

                infoItem(
                    icon: "lightbulb",
                    title: "When to Use Which?",
                    detail: "Use AccessorySetupKit for simple, user-initiated pairing of known accessories. Use CoreBluetooth when you need fine-grained control over scanning, services, and characteristics."
                )
            }
            .padding(.top, 8)
        }
    }

    private func infoItem(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    List {
        AccessorySetupInfoSection()
    }
}
