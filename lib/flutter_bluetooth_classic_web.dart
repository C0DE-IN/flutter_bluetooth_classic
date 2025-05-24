import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

class FlutterBluetoothClassicWeb {
  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'com.example/flutter_bluetooth_classic_state',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = FlutterBluetoothClassicWeb();
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'listen':
        return _handleListen(call.arguments);
      case 'isAvailable':
        return _isAvailable();
      case 'isEnabled':
        return _isEnabled();
      case 'startScan':
        return _startScan(call.arguments);
      case 'stopScan':
        return _stopScan();
      case 'connect':
        return _connect(call.arguments);
      case 'disconnect':
        return _disconnect(call.arguments);
      case 'write':
        return _write(call.arguments);
      case 'read':
        return _read(call.arguments);
      case 'getConnectedDevices':
        return _getConnectedDevices();
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details:
              'flutter_bluetooth_classic for web doesn\'t implement \'${call.method}\'',
        );
    }
  }

  Future<bool> _handleListen(dynamic arguments) async {
    // Web implementation for listen method
    return true;
  }

  Future<bool> _isAvailable() async {
    return _callJsMethod('isAvailable', []);
  }

  Future<bool> _isEnabled() async {
    return _callJsMethod('isEnabled', []);
  }

  Future<List<Map<String, dynamic>>> _startScan(dynamic arguments) async {
    final result = await _callJsMethod('startScan', [arguments]);
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  Future<bool> _stopScan() async {
    return _callJsMethod('stopScan', []);
  }

  Future<bool> _connect(dynamic arguments) async {
    return _callJsMethod('connect', [arguments]);
  }

  Future<bool> _disconnect(dynamic arguments) async {
    return _callJsMethod('disconnect', [arguments]);
  }

  Future<bool> _write(dynamic arguments) async {
    return _callJsMethod('write', [arguments]);
  }

  Future<String> _read(dynamic arguments) async {
    return _callJsMethod('read', [arguments]);
  }

  Future<List<Map<String, dynamic>>> _getConnectedDevices() async {
    final result = await _callJsMethod('getConnectedDevices', []);
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  Future<T> _callJsMethod<T>(String method, List<dynamic> args) async {
    try {
      if (hasProperty(globalThis, 'flutterBluetoothClassicWeb')) {
        final webPlugin = getProperty(globalThis, 'flutterBluetoothClassicWeb');
        if (webPlugin != null) {
          final jsArgs = args.jsify() as JSArray;
          final result = await callMethod(webPlugin, method, jsArgs).toDart;
          return result as T;
        } else {
          throw PlatformException(
            code: 'NotAvailable',
            message: 'Web Bluetooth plugin not initialized',
          );
        }
      } else {
        throw PlatformException(
          code: 'NotAvailable',
          message: 'Web Bluetooth not available',
        );
      }
    } catch (e) {
      throw PlatformException(
        code: 'Error',
        message: 'Failed to call $method: $e',
      );
    }
  }
}

@JS()
external JSObject get globalThis;

@JS()
external bool hasProperty(JSObject object, String property);

@JS()
external JSAny? getProperty(JSObject object, String property);

@JS()
external JSPromise callMethod(JSAny object, String method, JSArray args);
