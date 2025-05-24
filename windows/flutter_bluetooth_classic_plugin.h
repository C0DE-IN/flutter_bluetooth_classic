#ifndef FLUTTER_BLUETOOTH_CLASSIC_PLUGIN_H_
#define FLUTTER_BLUETOOTH_CLASSIC_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windows.h>
#include <winsock2.h>
#include <ws2bth.h>
#include <bluetoothapis.h>

class FlutterBluetoothClassicPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  FlutterBluetoothClassicPlugin();
  virtual ~FlutterBluetoothClassicPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void StartDiscovery(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void StopDiscovery(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void GetPairedDevices(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void ConnectToDevice(const std::string& address, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

void FlutterBluetoothClassicPluginRegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar);

#endif  // FLUTTER_BLUETOOTH_CLASSIC_PLUGIN_H_
