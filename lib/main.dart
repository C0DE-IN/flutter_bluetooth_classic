import 'package:flutter/material.dart';
import 'bluetooth-classic-package.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Classic Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BluetoothDemo(),
    );
  }
}

class BluetoothDemo extends StatefulWidget {
  const BluetoothDemo({Key? key}) : super(key: key);

  @override
  State<BluetoothDemo> createState() => _BluetoothDemoState();
}

class _BluetoothDemoState extends State<BluetoothDemo> {
  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();
  final List<BluetoothDevice> _devices = [];
  final TextEditingController _messageController = TextEditingController();
  String _status = 'Disconnected';
  String _receivedData = '';
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _setupBluetoothListeners();
  }

  void _setupBluetoothListeners() {
    _bluetooth.onStateChanged.listen((state) {
      setState(() {
        _status = state.status;
      });
    });

    _bluetooth.onConnectionChanged.listen((connection) {
      setState(() {
        _status = connection.status;
      });
    });

    _bluetooth.onDataReceived.listen((data) {
      setState(() {
        _receivedData += '${data.asString()}\n';
      });
    });
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _devices.clear();
    });

    try {
      bool enabled = await _bluetooth.isBluetoothEnabled();
      if (!enabled) {
        await _bluetooth.enableBluetooth();
      }
      await _bluetooth.startDiscovery();
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetooth.connect(device.address);
      setState(() {
        _connectedDevice = device;
      });
    } catch (e) {
      _showSnackBar('Connection error: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;
    try {
      await _bluetooth.sendString(_messageController.text);
      _messageController.clear();
    } catch (e) {
      _showSnackBar('Send error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Classic Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startDiscovery,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Status: $_status'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(device),
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
          ),
          if (_connectedDevice != null) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Text(_receivedData),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bluetooth.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
