import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic/flutter_bluetooth_classic.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bluetooth Classic Example'),
        ),
        body: const BluetoothTest(),
      ),
    );
  }
}

class BluetoothTest extends StatefulWidget {
  const BluetoothTest({Key? key}) : super(key: key);

  @override
  State<BluetoothTest> createState() => _BluetoothTestState();
}

class _BluetoothTestState extends State<BluetoothTest> {
  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();
  String _status = 'Unknown';

  @override
  void initState() {
    super.initState();
    _bluetooth.onStateChanged.listen((state) {
      setState(() {
        _status = state.status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Bluetooth Status: $_status'),
          ElevatedButton(
            onPressed: () async {
              final bool? enabled = await _bluetooth.enableBluetooth();
              print('Bluetooth enabled: $enabled');
            },
            child: const Text('Enable Bluetooth'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bluetooth.dispose();
    super.dispose();
  }
}
