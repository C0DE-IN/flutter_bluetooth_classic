package com.example.flutter_bluetooth_classic

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.flutter_bluetooth_classic.FlutterBluetoothClassicPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(FlutterBluetoothClassicPlugin())
    }
}
