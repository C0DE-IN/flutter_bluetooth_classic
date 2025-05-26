// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bluetooth_classic_serial/flutter_bluetooth_classic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterBluetoothClassic Tests', () {
    late FlutterBluetoothClassic bluetooth;

    setUp(() {
      bluetooth = FlutterBluetoothClassic();
    });

    test('Instance should be singleton', () {
      final instance1 = FlutterBluetoothClassic();
      final instance2 = FlutterBluetoothClassic();
      expect(instance1, equals(instance2));
    });

    test('Stream controllers should not be null', () {
      expect(bluetooth.onStateChanged, isNotNull);
      expect(bluetooth.onConnectionChanged, isNotNull);
      expect(bluetooth.onDataReceived, isNotNull);
    });

    // Note: Most Bluetooth functionality cannot be tested without actual hardware
    // These are just basic structural tests
  });
}
