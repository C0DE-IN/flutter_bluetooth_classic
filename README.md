# Flutter Bluetooth Classic

A Flutter plugin for Bluetooth Classic communication supporting both Android and iOS platforms.

## Features

* Bluetooth device discovery
* Connect to Bluetooth devices
* Send and receive data
* Monitor Bluetooth state changes
* Support for both Android and iOS

## Getting Started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_bluetooth_classic: ^1.0.0
```

## Usage

```dart
// Initialize Bluetooth
final bluetooth = FlutterBluetoothClassic();

// Check if Bluetooth is enabled
bool enabled = await bluetooth.isBluetoothEnabled();

// Start discovery
await bluetooth.startDiscovery();

// Connect to a device
await bluetooth.connect(deviceAddress);

// Send data
await bluetooth.sendString('Hello World');

// Listen for received data
bluetooth.onDataReceived.listen((data) {
  print('Received: ${data.asString()}');
});
```

## Permissions

### Android
Add these permissions to your AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
```

### iOS
Add these keys to your Info.plist:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need Bluetooth access for communication</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Need Bluetooth access for communication</string>
```

## Example

Check the `example` folder for a complete working example.

## Flutter implementation
```
// lib/flutter_bluetooth_classic.dart
```
## Android implementation
```
// android/src/main/kotlin/com/example/flutter_bluetooth_classic/FlutterBluetoothClassicPlugin.kt

```
## iOS implementation
```
// ios/Classes/SwiftFlutterBluetoothClassicPlugin.swift
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.