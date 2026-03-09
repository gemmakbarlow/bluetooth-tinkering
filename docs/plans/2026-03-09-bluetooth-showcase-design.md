# Bluetooth Showcase App — Design

## Purpose

A showcase/portfolio iOS app demonstrating Bluetooth (BLE) capabilities in 2026 using Apple's CoreBluetooth framework. Designed to be demo-friendly, functional, and cleanly architected.

## Platform & Stack

- **iOS 18+**, SwiftUI
- **@Observable** macro (Swift Observation framework)
- **CoreBluetooth** + **AccessorySetupKit** — no third-party dependencies
- **Blue-themed UI** throughout

## Architecture

### Layers

- **BluetoothManager** (`@Observable`) — single source of truth wrapping `CBCentralManager`, handles all delegate callbacks. Conforms to `BluetoothManaging` protocol for testability.
- **ViewModels** (`@Observable`) — one per feature, receive `BluetoothManager` via constructor injection.
- **Views** — SwiftUI, minimal logic, receive ViewModels via `@Environment`.
- **Models** — lightweight structs for discovered devices, services, characteristics.

### Dependency Injection

- All objects created at the composition root (App entry point).
- `BluetoothManager` and all ViewModels injected via `.environment()`.
- Views never instantiate ViewModels.
- `MockBluetoothManager` used for previews and tests.

```
App (composition root)
 +-- creates BluetoothManager
 +-- creates all ViewModels with manager injected
     +-- .environment(scannerViewModel)
     +-- .environment(accessorySetupViewModel)
     +-- .environment(backgroundViewModel)
     +-- .environment(dashboardViewModel)
         +-- ScannerTab -> @Environment(ScannerViewModel.self)
         +-- AccessorySetupTab -> @Environment(AccessorySetupViewModel.self)
         +-- BackgroundTab -> @Environment(BackgroundViewModel.self)
         +-- DashboardTab -> @Environment(DashboardViewModel.self)
```

## Features (4 Tabs)

### Scanner Tab

- Lists discovered BLE peripherals: name, RSSI signal indicator, advertised service UUIDs.
- Pull-to-refresh to restart scanning.
- Filter toggle: hide unnamed devices.
- Sort options: by signal strength or name.
- Tapping a device navigates (push) to Device Detail.
- Scan auto-stops after 30 seconds with manual rescan option.
- Empty state after reasonable scan duration.

### Accessory Setup Tab (AccessorySetupKit)

Demonstrates the modern iOS 18+ accessory onboarding experience using `AccessorySetupKit`:

- **Picker UI:** Button to present the system accessory picker (`ASAccessorySession.showPicker`), showing nearby BLE accessories with product images and names.
- **Discovery configuration:** Configurable `ASDiscoveryDescriptor` with Bluetooth service UUID and/or company identifier filtering.
- **Session lifecycle:** Displays `ASAccessorySession` state and events (activated, accessory added, accessory removed).
- **Previously paired accessories:** Lists accessories already associated with the app via `session.accessories`.
- **Accessory management:** Rename and remove paired accessories.
- **Comparison info:** Brief explanation contrasting AccessorySetupKit (modern, one-tap, privacy-first) with traditional CoreBluetooth scanning (manual, permission-heavy).

### Device Detail (pushed from Scanner)

- Connection state with connect/disconnect button.
- Once connected, lists services in expandable sections.
- Each characteristic supports:
  - **Read:** fetch and display current value.
  - **Write:** text input to write a value.
  - **Notify:** toggle subscription, show live updating values.
- Graceful handling of disconnection mid-browse.
- Connection timeout after ~10 seconds.
- Prevents double-tap on connect button.

### Background Monitor Tab

- Log/timeline of Bluetooth events including those received while backgrounded.
- Toggle to enable/disable background monitoring for a connected device.
- Info section explaining background BLE modes and state restoration.
- Event log capped at 100 entries, oldest dropped.

### Dashboard Tab

- Live data from a connected device's notifying characteristic.
- Simple line chart of recent values over time.
- Current value displayed prominently.
- **Mock data mode** when no device is connected, with simulated values.
- Prominent **purple "Simulated Data" badge** when in mock mode.
- Data gap detection: shows "No data" state if notifications stop.
- Prompt to switch to live data when a real device connects during mock mode.
- Toggle between live and mock data.

## Error Handling

### Bluetooth State

- **Off:** full-screen prompt to enable Bluetooth.
- **Unauthorized:** prompt explaining permission requirement with Settings guidance.
- **Unsupported:** message indicating no BLE support.
- Reactive — UI updates immediately on state changes.

### Accessory Setup

- **Picker cancelled:** Handle user dismissing the picker without selecting.
- **Discovery timeout:** Show message if no matching accessories found within timeout.
- **Session activation failure:** Display error if session cannot be activated.
- **No accessories configured:** Empty state explaining how AccessorySetupKit works and prompting to try the picker.

### Connection Lifecycle

- Connection timeout: ~10 seconds, then error and reset.
- Unexpected disconnection: inline alert, Scanner updated.
- Double-tap prevention on connect button.

### Background Monitor

- Warning if background mode entitlement is misconfigured.
- Log capped at 100 entries.

### Dashboard

- Stale data detection after notification timeout.
- Mock-to-live transition prompt.

## Theming

- Blue accent color throughout (navigation, tabs, buttons, charts, signal indicators).
- Purple badge for "Simulated Data" indicator on Dashboard.

## Testing Strategy (Unit Tests)

All ViewModels tested via `MockBluetoothManager` conforming to `BluetoothManaging` protocol.

### BluetoothManager

- State transitions (off -> on -> scanning -> connected).
- Peripheral discovery and deduplication (RSSI updates).
- Connection/disconnection state management.
- Scan auto-stop after timeout.

### ScannerViewModel

- Filtering unnamed devices.
- Sorting by RSSI and by name.
- Empty state trigger.

### DeviceDetailViewModel

- Connect/disconnect state.
- Service and characteristic discovery.
- Read/write/notify toggle state.
- Connection timeout handling.

### BackgroundViewModel

- Event log appending.
- Log cap at 100 entries.
- Background monitoring toggle.

### AccessorySetupViewModel

- Session event handling (accessory added, removed).
- Accessories list reflects session state.
- Picker presentation state management.
- Error state handling (cancelled, timeout, activation failure).

### DashboardViewModel

- Mock data when no device connected.
- `isSimulated` flag correctness.
- Data gap detection.
- Live device connection prompt during mock mode.

## Hardware Recommendation

An **ESP32 dev board** (e.g. ESP32-C3 SuperMini, ~$10-15) is recommended for full peripheral-side testing but is not required. The app is designed to work without specific hardware.
