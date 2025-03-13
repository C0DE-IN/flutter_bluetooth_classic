import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class FlutterBluetoothClassic {
  static const MethodChannel _channel =
      MethodChannel('com.example/flutter_bluetooth_classic');
  static const EventChannel _stateChannel =
      EventChannel('com.example/flutter_bluetooth_classic_state');
  static const EventChannel _connectionChannel =
      EventChannel('com.example/flutter_bluetooth_classic_connection');
  static const EventChannel _dataChannel =
      EventChannel('com.example/flutter_bluetooth_classic_data');

  // Singleton instance
  static FlutterBluetoothClassic? _instance;

  // Stream controllers
  final _stateStreamController = StreamController<BluetoothState>.broadcast();
  final _connectionStreamController =
      StreamController<BluetoothConnectionState>.broadcast();
  final _dataStreamController = StreamController<BluetoothData>.broadcast();

  // Public streams that can be subscribed to
  Stream<BluetoothState> get onStateChanged => _stateStreamController.stream;
  Stream<BluetoothConnectionState> get onConnectionChanged =>
      _connectionStreamController.stream;
  Stream<BluetoothData> get onDataReceived => _dataStreamController.stream;

  /// Factory constructor to maintain a single instance of the class
  factory FlutterBluetoothClassic() {
    _instance ??= FlutterBluetoothClassic._();
    return _instance!;
  }

  /// Private constructor that sets up the event listeners
  FlutterBluetoothClassic._() {
    // Listen for state changes
    _stateChannel.receiveBroadcastStream().listen((dynamic event) {
      _stateStreamController.add(BluetoothState.fromMap(event));
    });

    // Listen for connection changes
    _connectionChannel.receiveBroadcastStream().listen((dynamic event) {
      _connectionStreamController.add(BluetoothConnectionState.fromMap(event));
    });

    // Listen for data received
    _dataChannel.receiveBroadcastStream().listen((dynamic event) {
      _dataStreamController.add(BluetoothData.fromMap(event));
    });
  }

  /// Check if Bluetooth is supported on the device
  Future<bool> isBluetoothSupported() async {
    try {
      return await _channel.invokeMethod('isBluetoothSupported');
    } catch (e) {
      throw BluetoothException('Failed to check Bluetooth support: $e');
    }
  }

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    try {
      return await _channel.invokeMethod('isBluetoothEnabled');
    } catch (e) {
      throw BluetoothException('Failed to check Bluetooth status: $e');
    }
  }

  /// Request to enable Bluetooth
  Future<bool> enableBluetooth() async {
    try {
      return await _channel.invokeMethod('enableBluetooth');
    } catch (e) {
      throw BluetoothException('Failed to enable Bluetooth: $e');
    }
  }

  /// Get paired devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final List<dynamic> devices =
          await _channel.invokeMethod('getPairedDevices');
      return devices.map((device) => BluetoothDevice.fromMap(device)).toList();
    } catch (e) {
      throw BluetoothException('Failed to get paired devices: $e');
    }
  }

  /// Start discovery for nearby Bluetooth devices
  Future<bool> startDiscovery() async {
    try {
      return await _channel.invokeMethod('startDiscovery');
    } catch (e) {
      throw BluetoothException('Failed to start discovery: $e');
    }
  }

  /// Stop discovery
  Future<bool> stopDiscovery() async {
    try {
      return await _channel.invokeMethod('stopDiscovery');
    } catch (e) {
      throw BluetoothException('Failed to stop discovery: $e');
    }
  }

  /// Connect to a device
  Future<bool> connect(String address) async {
    try {
      return await _channel.invokeMethod('connect', {'address': address});
    } catch (e) {
      throw BluetoothException('Failed to connect to device: $e');
    }
  }

  /// Disconnect from a device
  Future<bool> disconnect() async {
    try {
      return await _channel.invokeMethod('disconnect');
    } catch (e) {
      throw BluetoothException('Failed to disconnect: $e');
    }
  }

  /// Send data to the connected device
  Future<bool> sendData(List<int> data) async {
    try {
      return await _channel.invokeMethod('sendData', {'data': data});
    } catch (e) {
      throw BluetoothException('Failed to send data: $e');
    }
  }

  /// Send string data to the connected device
  Future<bool> sendString(String message) async {
    try {
      final List<int> data = utf8.encode(message);
      return await sendData(data);
    } catch (e) {
      throw BluetoothException('Failed to send string: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _stateStreamController.close();
    _connectionStreamController.close();
    _dataStreamController.close();
  }
}

// Data Models

class BluetoothException implements Exception {
  final String message;

  BluetoothException(this.message);

  @override
  String toString() => 'BluetoothException: $message';
}

class BluetoothState {
  final bool isEnabled;
  final String status;

  BluetoothState({required this.isEnabled, required this.status});

  factory BluetoothState.fromMap(dynamic map) {
    return BluetoothState(
      isEnabled: map['isEnabled'],
      status: map['status'],
    );
  }
}

class BluetoothDevice {
  final String name;
  final String address;
  final bool paired;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.paired,
  });

  factory BluetoothDevice.fromMap(dynamic map) {
    return BluetoothDevice(
      name: map['name'] ?? 'Unknown',
      address: map['address'],
      paired: map['paired'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'paired': paired,
    };
  }
}

class BluetoothConnectionState {
  final bool isConnected;
  final String deviceAddress;
  final String status;

  BluetoothConnectionState({
    required this.isConnected,
    required this.deviceAddress,
    required this.status,
  });

  factory BluetoothConnectionState.fromMap(dynamic map) {
    return BluetoothConnectionState(
      isConnected: map['isConnected'],
      deviceAddress: map['deviceAddress'],
      status: map['status'],
    );
  }
}

class BluetoothData {
  final String deviceAddress;
  final List<int> data;

  BluetoothData({
    required this.deviceAddress,
    required this.data,
  });

  String asString() {
    return utf8.decode(data);
  }

  factory BluetoothData.fromMap(dynamic map) {
    return BluetoothData(
      deviceAddress: map['deviceAddress'],
      data: List<int>.from(map['data']),
    );
  }
}
