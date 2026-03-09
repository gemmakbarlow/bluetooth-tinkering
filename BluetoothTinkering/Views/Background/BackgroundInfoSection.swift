import SwiftUI

struct BackgroundInfoSection: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup("Background BLE Info", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                infoItem(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Background Mode",
                    detail: "The bluetooth-central background mode is enabled, allowing this app to scan for and communicate with BLE peripherals while in the background."
                )

                infoItem(
                    icon: "arrow.clockwise",
                    title: "State Restoration",
                    detail: "Core Bluetooth preserves your app's central manager state when the system terminates it. Upon relaunch, the system restores the manager with its connected peripherals and pending operations."
                )

                infoItem(
                    icon: "lightbulb",
                    title: "Testing Tips",
                    detail: "To test background BLE: connect to a device, press Home to background the app, then trigger a notification from the peripheral. Check this event log to verify events were received."
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
        BackgroundInfoSection()
    }
}
