#include "flutter_bluetooth_classic_plugin.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>

void FlutterBluetoothClassicPluginRegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_bluetooth_classic",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterBluetoothClassicPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterBluetoothClassicPlugin::FlutterBluetoothClassicPlugin() {}

FlutterBluetoothClassicPlugin::~FlutterBluetoothClassicPlugin() {}

void FlutterBluetoothClassicPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (method_call.method_name().compare("startDiscovery") == 0) {
    StartDiscovery(std::move(result));
  } else if (method_call.method_name().compare("stopDiscovery") == 0) {
    StopDiscovery(std::move(result));
  } else if (method_call.method_name().compare("getPairedDevices") == 0) {
    GetPairedDevices(std::move(result));
  } else if (method_call.method_name().compare("connectToDevice") == 0) {
    auto args = std::get<flutter::EncodableMap>(*method_call.arguments());
    auto address = std::get<std::string>(args[flutter::EncodableValue("address")]);
    ConnectToDevice(address, std::move(result));
  } else {
    result->NotImplemented();
  }
}

void FlutterBluetoothClassicPlugin::StartDiscovery(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  BLUETOOTH_DEVICE_SEARCH_PARAMS searchParams = { 0 };
  searchParams.dwSize = sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS);
  searchParams.fReturnAuthenticated = TRUE;
  searchParams.fReturnRemembered = TRUE;
  searchParams.fReturnUnknown = TRUE;
  searchParams.fReturnConnected = TRUE;
  searchParams.fIssueInquiry = TRUE;
  searchParams.cTimeoutMultiplier = 2;

  BLUETOOTH_DEVICE_INFO deviceInfo = { 0 };
  deviceInfo.dwSize = sizeof(BLUETOOTH_DEVICE_INFO);

  HBLUETOOTH_DEVICE_FIND hFind = BluetoothFindFirstDevice(&searchParams, &deviceInfo);
  
  flutter::EncodableList devices;
  
  if (hFind != NULL) {
    do {
      flutter::EncodableMap device;
      
      // Convert wide string to regular string
      std::wstring ws(deviceInfo.szName);
      std::string name(ws.begin(), ws.end());
      
      // Convert address to string
      char addressStr[18];
      sprintf_s(addressStr, "%02X:%02X:%02X:%02X:%02X:%02X",
                deviceInfo.Address.rgBytes[5],
                deviceInfo.Address.rgBytes[4],
                deviceInfo.Address.rgBytes[3],
                deviceInfo.Address.rgBytes[2],
                deviceInfo.Address.rgBytes[1],
                deviceInfo.Address.rgBytes[0]);
      
      device[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
      device[flutter::EncodableValue("address")] = flutter::EncodableValue(std::string(addressStr));
      device[flutter::EncodableValue("connected")] = flutter::EncodableValue(deviceInfo.fConnected);
      device[flutter::EncodableValue("remembered")] = flutter::EncodableValue(deviceInfo.fRemembered);
      
      devices.push_back(flutter::EncodableValue(device));
      
    } while (BluetoothFindNextDevice(hFind, &deviceInfo));
    
    BluetoothFindDeviceClose(hFind);
  }
  
  result->Success(flutter::EncodableValue(devices));
}

void FlutterBluetoothClassicPlugin::StopDiscovery(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  result->Success(flutter::EncodableValue(true));
}

void FlutterBluetoothClassicPlugin::GetPairedDevices(std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  StartDiscovery(std::move(result));
}

void FlutterBluetoothClassicPlugin::ConnectToDevice(const std::string& address, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Parse address string
  BLUETOOTH_ADDRESS btAddr = { 0 };
  int addr[6];
  if (sscanf_s(address.c_str(), "%02X:%02X:%02X:%02X:%02X:%02X",
               &addr[5], &addr[4], &addr[3], &addr[2], &addr[1], &addr[0]) == 6) {
    for (int i = 0; i < 6; i++) {
      btAddr.rgBytes[i] = (BYTE)addr[i];
    }
    
    // Create socket for connection
    SOCKET sock = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
    if (sock != INVALID_SOCKET) {
      SOCKADDR_BTH sockAddr = { 0 };
      sockAddr.addressFamily = AF_BTH;
      sockAddr.btAddr = btAddr;
      sockAddr.port = BT_PORT_ANY;
      
      if (connect(sock, (SOCKADDR*)&sockAddr, sizeof(sockAddr)) == 0) {
        result->Success(flutter::EncodableValue(true));
        closesocket(sock);
        return;
      }
      closesocket(sock);
    }
  }
  
  result->Error("CONNECTION_FAILED", "Failed to connect to device");
}
