class FlutterBluetoothClassicWeb {
  constructor() {
    this.connectedDevices = new Map();
    this.scanResults = [];
  }

  // Check if Bluetooth is available
  async isAvailable() {
    return 'bluetooth' in navigator;
  }

  // Check if Bluetooth is enabled
  async isEnabled() {
    if (!('bluetooth' in navigator)) {
      return false;
    }
    try {
      const availability = await navigator.bluetooth.getAvailability();
      return availability;
    } catch (error) {
      console.error('Error checking Bluetooth availability:', error);
      return false;
    }
  }

  // Start scanning for devices
  async startScan(options = {}) {
    try {
      const device = await navigator.bluetooth.requestDevice({
        acceptAllDevices: true,
        optionalServices: options.services || []
      });
      
      const deviceInfo = {
        id: device.id,
        name: device.name || 'Unknown Device',
        address: device.id, // Web Bluetooth doesn't expose MAC addresses
        type: 'unknown',
        isConnected: false
      };
      
      this.scanResults.push(deviceInfo);
      return [deviceInfo];
    } catch (error) {
      console.error('Error during device scan:', error);
      throw error;
    }
  }

  // Stop scanning (no-op for Web Bluetooth as it's user-initiated)
  async stopScan() {
    return true;
  }

  // Connect to a device
  async connect(deviceId) {
    try {
      const device = await navigator.bluetooth.requestDevice({
        acceptAllDevices: true
      });
      
      const server = await device.gatt.connect();
      
      this.connectedDevices.set(deviceId, {
        device: device,
        server: server,
        characteristics: new Map()
      });
      
      return true;
    } catch (error) {
      console.error('Error connecting to device:', error);
      throw error;
    }
  }

  // Disconnect from a device
  async disconnect(deviceId) {
    const connection = this.connectedDevices.get(deviceId);
    if (connection && connection.server) {
      connection.server.disconnect();
      this.connectedDevices.delete(deviceId);
      return true;
    }
    return false;
  }

  // Write data to a device
  async write(deviceId, data) {
    const connection = this.connectedDevices.get(deviceId);
    if (!connection) {
      throw new Error('Device not connected');
    }

    try {
      // This is a simplified implementation
      // In a real scenario, you'd need to specify the service and characteristic UUIDs
      const services = await connection.server.getPrimaryServices();
      if (services.length > 0) {
        const characteristics = await services[0].getCharacteristics();
        if (characteristics.length > 0) {
          const writeCharacteristic = characteristics.find(c => 
            c.properties.write || c.properties.writeWithoutResponse
          );
          
          if (writeCharacteristic) {
            const encoder = new TextEncoder();
            const encodedData = typeof data === 'string' ? encoder.encode(data) : data;
            await writeCharacteristic.writeValue(encodedData);
            return true;
          }
        }
      }
      throw new Error('No writable characteristic found');
    } catch (error) {
      console.error('Error writing data:', error);
      throw error;
    }
  }

  // Read data from a device
  async read(deviceId) {
    const connection = this.connectedDevices.get(deviceId);
    if (!connection) {
      throw new Error('Device not connected');
    }

    try {
      const services = await connection.server.getPrimaryServices();
      if (services.length > 0) {
        const characteristics = await services[0].getCharacteristics();
        if (characteristics.length > 0) {
          const readCharacteristic = characteristics.find(c => c.properties.read);
          
          if (readCharacteristic) {
            const value = await readCharacteristic.readValue();
            const decoder = new TextDecoder();
            return decoder.decode(value);
          }
        }
      }
      throw new Error('No readable characteristic found');
    } catch (error) {
      console.error('Error reading data:', error);
      throw error;
    }
  }

  // Get connected devices
  getConnectedDevices() {
    return Array.from(this.connectedDevices.keys()).map(deviceId => ({
      id: deviceId,
      name: 'Connected Device',
      address: deviceId,
      type: 'unknown',
      isConnected: true
    }));
  }
}

// Register the plugin globally
window.flutterBluetoothClassicWeb = new FlutterBluetoothClassicWeb();
