import SwiftUI

struct DashboardView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @State private var showLiveDataPrompt = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.showNoData {
                    noDataView
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                if viewModel.dataPoints.isEmpty && viewModel.useMockData {
                    viewModel.startMockData()
                }
            }
            .onChange(of: viewModel.shouldPromptForLiveData) { _, shouldPrompt in
                if shouldPrompt && !viewModel.hasDeclinedLiveData {
                    showLiveDataPrompt = true
                }
            }
            // Future Consideration: Unify alert patterns across views (DashboardView, DeviceDetailView,
            // AccessorySetupView, PairedAccessoryRow) into a shared view modifier.
            .alert(
                "Live Data Available",
                isPresented: $showLiveDataPrompt
            ) {
                Button("Switch to Live Data") {
                    viewModel.switchToLiveData()
                }
                Button("Keep Simulated", role: .cancel) {
                    viewModel.hasDeclinedLiveData = true
                }
            } message: {
                Text("A Bluetooth device is connected. Would you like to switch to live data?")
            }
        }
    }

    // MARK: - Dashboard Content

    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                currentValueSection

                if viewModel.isSimulated {
                    SimulatedDataBadge()
                }

                if viewModel.isDataStale {
                    Label("No data received recently", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }

                SimpleLineChart(dataPoints: viewModel.dataPoints)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Current Value

    private var currentValueSection: some View {
        VStack(spacing: 4) {
            if let value = viewModel.currentValue {
                Text(String(format: "%.1f", value))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .contentTransition(.numericText())
            } else {
                Text("--")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - No Data

    private var noDataView: some View {
        ContentUnavailableView(
            "No Data",
            systemImage: "chart.line.downtrend.xyaxis",
            description: Text("Connect a Bluetooth device to start receiving data.")
        )
    }
}

// MARK: - Previews

#Preview("Mock Data") {
    let mock = MockBluetoothManager()
    let viewModel = DashboardViewModel(manager: mock)

    DashboardView()
        .environment(viewModel)
}

#Preview("No Data") {
    let mock = MockBluetoothManager()
    let viewModel = DashboardViewModel(manager: mock)
    let _ = { viewModel.useMockData = false }()

    DashboardView()
        .environment(viewModel)
}
