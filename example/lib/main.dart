import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_classic/bluetooth-classic-package.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    try {
      bool isSupported = await _bluetooth.isBluetoothSupported();
      if (!isSupported) {
        setState(() => _status = 'Bluetooth not supported');
        return;
      }

      bool isEnabled = await _bluetooth.isBluetoothEnabled();
      if (!isEnabled) {
        await _bluetooth.enableBluetooth();
      }

      _listenToBluetoothState();
      _listenToConnectionState();
      _listenToData();
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  void _listenToBluetoothState() {
    _bluetooth.onStateChanged.listen((state) {
      setState(() => _status = 'Bluetooth ${state.status}');
    });
  }

  void _listenToConnectionState() {
    _bluetooth.onConnectionChanged.listen((state) {
      setState(() {
        if (!state.isConnected) {
          _connectedDevice = null;
        }
        _status = 'Connection: ${state.status}';
      });
    });
  }

  void _listenToData() {
    _bluetooth.onDataReceived.listen((data) {
      setState(() => _status = 'Received: ${data.asString()}');
    });
  }

  Future<void> _scanDevices() async {
    try {
      setState(() => _status = 'Scanning...');
      List<BluetoothDevice> paired = await _bluetooth.getPairedDevices();
      setState(() => _devices = paired);
      await _bluetooth.startDiscovery();
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      setState(() => _status = 'Connecting...');
      bool connected = await _bluetooth.connect(device.address);
      if (connected) {
        setState(() => _connectedDevice = device);
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    try {
      await _bluetooth.sendString(message);
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Bluetooth Classic Example')),
        body: Column(
          children: [
            Text(_status),
            ElevatedButton(
              onPressed: _scanDevices,
              child: const Text('Scan Devices'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return ListTile(
                    title: Text(device.name),
                    subtitle: Text(device.address),
                    trailing: _connectedDevice?.address == device.address
                        ? const Icon(Icons.bluetooth_connected)
                        : const Icon(Icons.bluetooth),
                    onTap: () => _connect(device),
                  );
                },
              ),
            ),
            if (_connectedDevice != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onSubmitted: _sendMessage,
                        decoration: const InputDecoration(
                          hintText: 'Send message',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bluetooth.dispose();
    super.dispose();
  }
}
