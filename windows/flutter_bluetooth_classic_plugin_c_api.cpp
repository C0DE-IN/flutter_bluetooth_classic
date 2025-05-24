#include "include/flutter_bluetooth_classic/flutter_bluetooth_classic_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_bluetooth_classic_plugin.h"

void FlutterBluetoothClassicPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_bluetooth_classic::FlutterBluetoothClassicPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
