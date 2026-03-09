# Simulator Fallback Mode Design

## Problem

The iOS Simulator does not support Bluetooth Low Energy. The app shows a full-screen "Bluetooth Not Supported" overlay with no way to interact with any features.

## Solution

Add an `ApplicationMode` enum (`.standard` / `.demo`) that swaps the real `BluetoothManager` for a `MockBluetoothManager` with simulated responses. Accessible via a floating gear button and from the Bluetooth state overlay itself.

## Architecture

### ApplicationMode Enum

```swift
enum ApplicationMode {
    case standard
    case demo
}
```

### AppSettings Observable

- `mode: ApplicationMode` — defaults to `.standard`
- Holds both a real `BluetoothManager` and a `MockBluetoothManager`
- `activeManager: any BluetoothManaging` — returns the appropriate manager based on mode
- When mode changes, ViewModels are re-created with the new active manager

### Composition Root Changes

- `BluetoothTinkeringApp` creates `AppSettings` which owns both managers
- All ViewModels derive from `appSettings.activeManager`
- ViewModels are re-created when the mode changes

## UI Changes

### BluetoothStateOverlay

- When state is `.unsupported`, add a "Use Demo Mode" button below the existing guidance text
- Tapping sets `appSettings.mode = .demo`, which dismisses the overlay

### Floating Gear Button

- Persistent floating button in the top-right corner of `ContentView`, overlaid above tab content
- Opens a Settings sheet on tap

### Settings Sheet

- Demo Mode toggle (with comment: if more ApplicationMode cases are added, change to a Picker)
- About section (app name, version)

### Demo Mode Indicator

- When in `.demo` mode, show a persistent "Demo Mode" pill/banner visible app-wide
- Style similar to existing "Simulated Data" badge (purple background)

## MockBluetoothManager Enhancements

### Simulated Scanning

`startScanning()` auto-generates 3-4 fake peripherals after a brief delay:
- "Heart Rate Monitor" (RSSI -45, service 180D)
- "Temperature Sensor" (RSSI -62, service 1809)
- "Blood Pressure" (RSSI -78, service 1810)
- One unnamed peripheral (RSSI -88)

### Simulated Connection

`connect()` simulates a successful connection after a short delay, then populates mock services and characteristics.

## Testing

- Existing tests use `MockBluetoothManager` and are unaffected
- Add tests for `AppSettings` mode switching
- Add tests for enhanced mock scanning/connection behavior
