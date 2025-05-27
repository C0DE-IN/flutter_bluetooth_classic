## 1.0.2

### Bug Fixes
- 🔧 Fixed MissingPluginException errors by correcting channel name mismatches
- ✅ Updated Android, iOS, and Windows plugin implementations with proper channel names
- 🛠️ Fixed Android Bluetooth permissions in plugin manifest
- 📱 Created working example app with comprehensive Bluetooth demo
- 🔍 Fixed API usage in example to match singleton pattern
- ⚡ Improved error handling and user feedback in example app
- 🎯 Added support for Android 12+ Bluetooth permissions

## 1.0.1

### Bug Fixes
- ✅ Updated repository URLs to correct GitHub location
- ✅ Improved package metadata for pub.dev publication
- ✅ Removed unsupported web platform references
- 🔧 Updated Android package structure for better compatibility

## 1.0.0

### Features
- ✨ Initial release of Flutter Bluetooth Classic plugin
- 🔍 Device discovery and pairing
- 🔗 Connection management for Android, iOS, and Windows
- 📡 Bidirectional data transmission
- 📱 Multi-platform support (Android, iOS, Windows)
- 🔄 Real-time data streaming
- 🛡️ Robust error handling and connection management

### Platform Support
- ✅ Android: Full Bluetooth Classic support
- ✅ iOS: MFi accessory framework integration
- ✅ Windows: Native Windows Bluetooth API integration

### API
- `FlutterBluetoothClassic.instance` - Main plugin interface
- `BluetoothConnection.toAddress()` - Device connection
- Device discovery and enumeration
- Data transmission and reception
- Connection state management
