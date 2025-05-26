import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bluetooth Classic Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BluetoothScreen(),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  BluetoothScreenState createState() => BluetoothScreenState();
}

class BluetoothScreenState extends State<BluetoothScreen> {
  static const MethodChannel _mainChannel = MethodChannel(
      'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic');
  static const MethodChannel _stateChannel = MethodChannel(
      'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic_state');
  static const MethodChannel _dataChannel = MethodChannel(
      'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic_data');
  static const MethodChannel _connectionChannel = MethodChannel(
      'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic_connection');

  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _connectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;
  bool _bluetoothEnabled = false;
  final List<String> _receivedMessages = [];
  final TextEditingController _messageController = TextEditingController();
  Timer? _dataPollingTimer;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    _dataPollingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeBluetooth() async {
    try {
      // Check if Bluetooth is available and enabled
      bool isAvailable = await _stateChannel.invokeMethod('isAvailable');
      bool isEnabled = await _stateChannel.invokeMethod('isEnabled');

      setState(() {
        _bluetoothEnabled = isAvailable && isEnabled;
      });

      if (_bluetoothEnabled) {
        _loadPairedDevices();
      }
    } catch (e) {
      _showError('Failed to initialize Bluetooth: $e');
    }
  }

  Future<void> _loadPairedDevices() async {
    try {
      final List<dynamic> devices =
          await _connectionChannel.invokeMethod('getPairedDevices');
      setState(() {
        _devices = devices.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      _showError('Failed to load paired devices: $e');
    }
  }

  Future<void> _startDiscovery() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final List<dynamic> devices =
          await _connectionChannel.invokeMethod('startDiscovery');
      setState(() {
        _devices = devices.cast<Map<String, dynamic>>();
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showError('Failed to start discovery: $e');
    }
  }

  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    if (_isConnected) {
      _showError('Already connected to a device. Disconnect first.');
      return;
    }

    try {
      _showInfo('Connecting to ${device['name']}...');

      bool connected = await _mainChannel.invokeMethod('connect', {
        'address': device['address'],
      });

      if (connected) {
        setState(() {
          _connectedDevice = device;
          _isConnected = true;
        });

        // Start listening for data
        await _dataChannel.invokeMethod('listen', {
          'device': device['address'],
        });

        // Start polling for data
        _startDataPolling();

        _showSuccess('Connected to ${device['name']}');
      } else {
        _showError('Failed to connect to ${device['name']}');
      }
    } catch (e) {
      _showError('Connection error: $e');
    }
  }

  Future<void> _disconnect() async {
    if (!_isConnected || _connectedDevice == null) return;

    try {
      await _mainChannel.invokeMethod('disconnect', {
        'address': _connectedDevice!['address'],
      });

      _dataPollingTimer?.cancel();

      setState(() {
        _connectedDevice = null;
        _isConnected = false;
        _receivedMessages.clear();
      });

      _showSuccess('Disconnected successfully');
    } catch (e) {
      _showError('Disconnect error: $e');
    }
  }

  void _startDataPolling() {
    _dataPollingTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isConnected || _connectedDevice == null) {
        timer.cancel();
        return;
      }

      try {
        int available = await _mainChannel.invokeMethod('available', {
          'address': _connectedDevice!['address'],
        });

        if (available > 0) {
          String data = await _mainChannel.invokeMethod('readData', {
            'address': _connectedDevice!['address'],
          });

          if (data.isNotEmpty) {
            setState(() {
              _receivedMessages
                  .add('${DateTime.now().toString().substring(11, 19)}: $data');
            });
          }
        }
      } catch (e) {
        // Silently handle polling errors to avoid spam
      }
    });
  }

  Future<void> _sendMessage() async {
    if (!_isConnected || _connectedDevice == null) {
      _showError('Not connected to any device');
      return;
    }

    String message = _messageController.text.trim();
    if (message.isEmpty) {
      _showError('Please enter a message');
      return;
    }

    try {
      bool sent = await _mainChannel.invokeMethod('writeData', {
        'address': _connectedDevice!['address'],
        'data': '$message\n', // Add newline for better compatibility
      });

      if (sent) {
        setState(() {
          _receivedMessages.add(
              '${DateTime.now().toString().substring(11, 19)}: SENT: $message');
        });
        _messageController.clear();
      } else {
        _showError('Failed to send message');
      }
    } catch (e) {
      _showError('Send error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Classic Example'),
        actions: [
          if (!_bluetoothEnabled)
            const Icon(Icons.bluetooth_disabled, color: Colors.red)
          else if (_isConnected)
            const Icon(Icons.bluetooth_connected, color: Colors.green)
          else
            const Icon(Icons.bluetooth, color: Colors.white),
        ],
      ),
      body: !_bluetoothEnabled
          ? _buildBluetoothDisabledView()
          : _isConnected
              ? _buildConnectedView()
              : _buildDeviceListView(),
    );
  }

  Widget _buildBluetoothDisabledView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Bluetooth is not available or enabled',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeBluetooth,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startDiscovery,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _loadPairedDevices,
                icon: const Icon(Icons.refresh),
                label: const Text('Paired'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _devices.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.devices, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No devices found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap "Scan for Devices" to discover nearby devices',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: device['isConnected'] == true
                              ? Colors.green
                              : Colors.blue,
                        ),
                        title: Text(device['name'] ?? 'Unknown Device'),
                        subtitle: Text(device['address'] ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () => _connectToDevice(device),
                          child: const Text('Connect'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildConnectedView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.bluetooth_connected, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected to:',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          _connectedDevice!['name'] ?? 'Unknown Device',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _connectedDevice!['address'] ?? '',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _disconnect,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _receivedMessages.isEmpty
                        ? const Center(
                            child: Text(
                              'No messages yet...\nSend a message or wait for incoming data',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: _receivedMessages.length,
                            itemBuilder: (context, index) {
                              final message = _receivedMessages[
                                  _receivedMessages.length - 1 - index];
                              final isSent = message.contains('SENT:');
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSent
                                      ? Colors.blue.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: isSent
                                        ? Colors.blue.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Enter message to send...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendMessage,
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
