import 'dart:async';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class FlutterBluetoothClassicPlatform extends PlatformInterface {
  FlutterBluetoothClassicPlatform() : super(token: _token);

  static final Object _token = Object();
  static FlutterBluetoothClassicPlatform _instance = _DefaultPlatform();

  static FlutterBluetoothClassicPlatform get instance => _instance;

  static set instance(FlutterBluetoothClassicPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // State streams
  Stream<Map<String, dynamic>> get stateStream;
  Stream<Map<String, dynamic>> get connectionStream;
  Stream<List<int>> get dataStream;

  // Methods
  Future<bool> isBluetoothSupported();
  Future<bool> isBluetoothEnabled();
  Future<bool> enableBluetooth();
  Future<List<Map<String, dynamic>>> getPairedDevices();
  Future<bool> startDiscovery();
  Future<bool> stopDiscovery();
  Future<bool> connect(String address);
  Future<bool> disconnect();
  Future<bool> sendData(List<int> data);
}

class _DefaultPlatform extends FlutterBluetoothClassicPlatform {
  static const MethodChannel _channel =
      MethodChannel('flutter_bluetooth_classic');
  static const EventChannel _stateChannel =
      EventChannel('flutter_bluetooth_classic_state');
  static const EventChannel _connectionChannel =
      EventChannel('flutter_bluetooth_classic_connection');
  static const EventChannel _dataChannel =
      EventChannel('flutter_bluetooth_classic_data');

  @override
  Stream<Map<String, dynamic>> get stateStream =>
      _stateChannel.receiveBroadcastStream().cast<Map<String, dynamic>>();

  @override
  Stream<Map<String, dynamic>> get connectionStream =>
      _connectionChannel.receiveBroadcastStream().cast<Map<String, dynamic>>();

  @override
  Stream<List<int>> get dataStream =>
      _dataChannel.receiveBroadcastStream().cast<List<int>>();

  @override
  Future<bool> isBluetoothSupported() async {
    return await _channel.invokeMethod('isBluetoothSupported') ?? false;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    return await _channel.invokeMethod('isBluetoothEnabled') ?? false;
  }

  @override
  Future<bool> enableBluetooth() async {
    return await _channel.invokeMethod('enableBluetooth') ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> getPairedDevices() async {
    final result = await _channel.invokeMethod('getPairedDevices');
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  @override
  Future<bool> startDiscovery() async {
    return await _channel.invokeMethod('startDiscovery') ?? false;
  }

  @override
  Future<bool> stopDiscovery() async {
    return await _channel.invokeMethod('stopDiscovery') ?? false;
  }

  @override
  Future<bool> connect(String address) async {
    return await _channel.invokeMethod('connect', {'address': address}) ??
        false;
  }

  @override
  Future<bool> disconnect() async {
    return await _channel.invokeMethod('disconnect') ?? false;
  }

  @override
  Future<bool> sendData(List<int> data) async {
    return await _channel.invokeMethod('sendData', {'data': data}) ?? false;
  }
}
