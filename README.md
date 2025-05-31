# Flutter Bluetooth Classic

A Flutter plugin for Bluetooth Classic communication supporting Android, iOS, and Windows platforms.

## Features

- 🔍 **Device Discovery**: Scan for and discover nearby Bluetooth Classic devices
- 🔗 **Connection Management**: Connect and disconnect from Bluetooth devices
- 📡 **Data Transmission**: Send and receive data over Bluetooth connections
- 📱 **Multi-Platform**: Supports Android, iOS, and Windows
- 🔄 **Real-time Communication**: Stream data for real-time applications

## Platform Support

| Platform | Support |
|----------|---------|
| Android  | ✅      |
| iOS      | ✅      |
| Windows  | ✅      |
| macOS    | ❌      |
| Linux    | ❌      |
| Web      | ❌      |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_bluetooth_classic_serial: ^1.0.1
```

Then run:

```bash
flutter pub get
```

## Permissions

### Android

Add these permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- For Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth access to communicate with devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth access to communicate with devices</string>
```

### Windows

Bluetooth capability is automatically included in the Windows implementation.

## Usage

### Basic Example

```dart
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

class BluetoothService {
  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic.instance;

  // Check if Bluetooth is available
  Future<bool> isBluetoothAvailable() async {
    return await _bluetooth.isAvailable;
  }

  // Get paired devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await _bluetooth.getPairedDevices();
  }

  // Connect to a device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      return connection.isConnected;
    } catch (e) {
      print('Connection failed: $e');
      return false;
    }
  }

  // Send data
  Future<void> sendData(BluetoothConnection connection, String data) async {
    connection.output.add(Uint8List.fromList(data.codeUnits));
    await connection.output.allSent;
  }

  // Listen for incoming data
  void listenForData(BluetoothConnection connection) {
    connection.input!.listen((Uint8List data) {
      String received = String.fromCharCodes(data);
      print('Received: $received');
    });
  }
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothConnection? _connection;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      List<BluetoothDevice> devices = await _bluetooth.getPairedDevices();
      setState(() {
        _devices = devices;
      });
    } catch (e) {
      print('Error loading devices: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        _connection = connection;
        _isConnected = true;
      });

      // Listen for incoming data
      _connection!.input!.listen((Uint8List data) {
        String received = String.fromCharCodes(data);
        print('Received: $received');
      });

    } catch (e) {
      print('Connection failed: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    if (_connection != null && _isConnected) {
      _connection!.output.add(Uint8List.fromList(message.codeUnits));
      await _connection!.output.allSent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Classic')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devices[index];
                return ListTile(
                  title: Text(device.name ?? 'Unknown Device'),
                  subtitle: Text(device.address),
                  onTap: () => _connectToDevice(device),
                );
              },
            ),
          ),
          if (_isConnected)
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => _sendMessage('Hello Bluetooth!'),
                child: Text('Send Message'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }
}
```

## API Reference

### FlutterBluetoothClassic

Main class for Bluetooth operations.

#### Properties

- `isAvailable` → `Future<bool>`: Check if Bluetooth is available
- `isEnabled` → `Future<bool>`: Check if Bluetooth is enabled

#### Methods

- `getPairedDevices()` → `Future<List<BluetoothDevice>>`: Get list of paired devices
- `startDiscovery()` → `Future<List<BluetoothDevice>>`: Start device discovery

### BluetoothConnection

Represents a connection to a Bluetooth device.

#### Static Methods

- `toAddress(String address)` → `Future<BluetoothConnection>`: Connect to device by address

#### Properties

- `isConnected` → `bool`: Connection status
- `input` → `Stream<Uint8List>`: Incoming data stream
- `output` → `IOSink`: Outgoing data sink

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please file an issue on our [GitHub repository](https://github.com/C0DE-IN/flutter_bluetooth_classic_serial/issues).