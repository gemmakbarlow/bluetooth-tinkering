import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Scanner")
                .tabItem {
                    Label("Scanner", systemImage: "antenna.radiowaves.left.and.right")
                }

            Text("Accessory Setup")
                .tabItem {
                    Label("Setup", systemImage: "plus.circle")
                }

            Text("Background Monitor")
                .tabItem {
                    Label("Monitor", systemImage: "eye")
                }

            Text("Dashboard")
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    ContentView()
}
