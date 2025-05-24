import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import './flutter_bluetooth_classic_platform_interface.dart';

class BluetoothDevice {
  final String name;
  final String address;
  final bool connected;
  final bool remembered;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.connected,
    required this.remembered,
  });

  factory BluetoothDevice.fromMap(Map<String, dynamic> map) {
    return BluetoothDevice(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      connected: map['connected'] ?? false,
      remembered: map['remembered'] ?? false,
    );
  }
}

class BluetoothService {
  static final FlutterBluetoothClassicPlatform _platform =
      FlutterBluetoothClassicPlatform.instance;

  // Streams
  static Stream<Map<String, dynamic>> get stateStream => _platform.stateStream;
  static Stream<Map<String, dynamic>> get connectionStream =>
      _platform.connectionStream;
  static Stream<List<int>> get dataStream => _platform.dataStream;

  static Future<bool> isBluetoothSupported() async {
    try {
      return await _platform.isBluetoothSupported();
    } catch (e) {
      if (kDebugMode) print('Error checking Bluetooth support: $e');
      return false;
    }
  }

  static Future<bool> isBluetoothEnabled() async {
    try {
      return await _platform.isBluetoothEnabled();
    } catch (e) {
      if (kDebugMode) print('Error checking Bluetooth state: $e');
      return false;
    }
  }

  static Future<List<BluetoothDevice>> startDiscovery() async {
    try {
      if (kIsWeb) {
        throw PlatformException(
          code: 'WEB_LIMITATION',
          message: 'Device discovery not supported on web',
          details:
              'Web browsers only support Bluetooth Low Energy (BLE) with user interaction',
        );
      }

      final devices = await _platform.getPairedDevices();
      return devices.map((device) => BluetoothDevice.fromMap(device)).toList();
    } catch (e) {
      if (kDebugMode) print('Error starting discovery: $e');
      rethrow;
    }
  }

  static Future<bool> stopDiscovery() async {
    try {
      return await _platform.stopDiscovery();
    } catch (e) {
      if (kDebugMode) print('Error stopping discovery: $e');
      return false;
    }
  }

  static Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      if (kIsWeb) {
        throw PlatformException(
          code: 'WEB_LIMITATION',
          message: 'Paired devices not accessible on web',
          details:
              'Web browsers do not provide access to paired Bluetooth devices',
        );
      }

      final devices = await _platform.getPairedDevices();
      return devices.map((device) => BluetoothDevice.fromMap(device)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting paired devices: $e');
      rethrow;
    }
  }

  static Future<bool> connectToDevice(String address) async {
    try {
      if (kIsWeb) {
        throw PlatformException(
          code: 'WEB_LIMITATION',
          message: 'Bluetooth Classic not supported on web',
          details:
              'Web browsers only support Bluetooth Low Energy (BLE) connections',
        );
      }

      return await _platform.connect(address);
    } catch (e) {
      if (kDebugMode) print('Error connecting to device: $e');
      rethrow;
    }
  }

  static Future<bool> disconnect() async {
    try {
      return await _platform.disconnect();
    } catch (e) {
      if (kDebugMode) print('Error disconnecting: $e');
      return false;
    }
  }

  static Future<bool> sendData(List<int> data) async {
    try {
      if (kIsWeb) {
        throw PlatformException(
          code: 'WEB_LIMITATION',
          message: 'Bluetooth Classic communication not supported on web',
          details:
              'Web browsers only support Bluetooth Low Energy (BLE) communication',
        );
      }

      return await _platform.sendData(data);
    } catch (e) {
      if (kDebugMode) print('Error sending data: $e');
      rethrow;
    }
  }

  // Web-specific helper to show platform limitations
  static String getWebLimitationsMessage() {
    return '''
Web Platform Bluetooth Limitations:

• Bluetooth Classic (SPP/RFCOMM) is not supported
• Only Bluetooth Low Energy (BLE) is available
• Device discovery requires user interaction
• No access to paired devices list
• Manual device selection through browser prompts

For Bluetooth Classic functionality, please use:
• Windows, macOS, Linux, Android, or iOS platforms
''';
  }
}
