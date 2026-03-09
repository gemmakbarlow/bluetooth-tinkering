import Foundation
import Observation

struct DataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

@MainActor
@Observable
final class DashboardViewModel {
    private let manager: any BluetoothManaging
    private var mockTimer: Timer?
    private let noDataTimeout: TimeInterval = 10

    var dataPoints: [DataPoint] = []
    var useMockData: Bool = true
    var lastReceivedDate: Date?

    var isSimulated: Bool {
        useMockData || manager.connectedPeripheral == nil
    }

    var currentValue: Double? {
        dataPoints.last?.value
    }

    var shouldPromptForLiveData: Bool {
        manager.connectedPeripheral != nil && useMockData
    }

    var showNoData: Bool {
        dataPoints.isEmpty && !useMockData
    }

    init(manager: any BluetoothManaging) {
        self.manager = manager
    }

    func startMockData() {
        useMockData = true
        mockTimer?.invalidate()
        mockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.addMockDataPoint()
            }
        }
    }

    func stopMockData() {
        mockTimer?.invalidate()
        mockTimer = nil
    }

    func switchToLiveData() {
        stopMockData()
        useMockData = false
        dataPoints = []
    }

    func addLiveDataPoint(_ value: Double) {
        lastReceivedDate = Date()
        let point = DataPoint(timestamp: Date(), value: value)
        dataPoints.append(point)
        trimDataPoints()
    }

    private func addMockDataPoint() {
        let base = 75.0
        let variation = Double.random(in: -15...15)
        let point = DataPoint(timestamp: Date(), value: base + variation)
        dataPoints.append(point)
        trimDataPoints()
    }

    private func trimDataPoints() {
        if dataPoints.count > 60 {
            dataPoints.removeFirst(dataPoints.count - 60)
        }
    }
}
