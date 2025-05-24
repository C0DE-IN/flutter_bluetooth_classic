import 'package:flutter/material.dart';
import 'bluetooth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bluetooth Classic',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Bluetooth Classic Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;

  void _startDiscovery() async {
    setState(() {
      _isScanning = true;
    });

    final devices = await BluetoothService.startDiscovery();

    setState(() {
      _devices = devices;
      _isScanning = false;
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    final success = await BluetoothService.connectToDevice(device.address);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Connected to ${device.name}'
              : 'Failed to connect to ${device.name}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isScanning ? null : _startDiscovery,
              child: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(
                      device.name.isEmpty ? 'Unknown Device' : device.name),
                  subtitle: Text(device.address),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (device.connected)
                        const Icon(Icons.bluetooth_connected,
                            color: Colors.green),
                      if (device.remembered)
                        const Icon(Icons.star, color: Colors.blue),
                      ElevatedButton(
                        onPressed: () => _connectToDevice(device),
                        child: const Text('Connect'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
