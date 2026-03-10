import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Future Consideration: If more ApplicationMode cases are added,
                    // change this Toggle to a Picker.
                    Toggle("Demo Mode", isOn: Binding(
                        get: { appSettings.isDemoMode },
                        set: { $0 ? appSettings.enableDemoMode() : appSettings.disableDemoMode() }
                    ))
                } footer: {
                    Text("Use simulated Bluetooth devices when real hardware is unavailable (e.g. iOS Simulator).")
                }

                Section("About") {
                    LabeledContent("App", value: "Bluetooth Tinkering")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let appSettings = AppSettings()
    SettingsView()
        .environment(appSettings)
}
