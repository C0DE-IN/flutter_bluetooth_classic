#include "flutter_bluetooth_classic_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <bluetoothapis.h>
#include <ws2bth.h>
#include <initguid.h>

#include <memory>
#include <sstream>
#include <vector>
#include <thread>
#include <mutex>

namespace flutter_bluetooth_classic {

// static
void FlutterBluetoothClassicPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  // Register the main channel
  auto main_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.example/flutter_bluetooth_classic",
          &flutter::StandardMethodCodec::GetInstance());

  // Register the state channel
  auto state_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.example/flutter_bluetooth_classic_state",
          &flutter::StandardMethodCodec::GetInstance());

  // Register the data channel
  auto data_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.example/flutter_bluetooth_classic_data",
          &flutter::StandardMethodCodec::GetInstance());

  // Register the connection channel
  auto connection_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.example/flutter_bluetooth_classic_connection",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterBluetoothClassicPlugin>();

  main_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  state_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  data_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  connection_channel->SetMethodCallHandler(
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
  
  const std::string& method = method_call.method_name();
  
  // Data channel methods - handle these first
  if (method.compare("listen") == 0) {
    // Check if this is a data channel listen request
    if (method_call.arguments()) {
      const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (args) {
        auto device_it = args->find(flutter::EncodableValue("device"));
        if (device_it != args->end()) {
          const auto* device_str = std::get_if<std::string>(&device_it->second);
          if (device_str) {
            std::string debug_msg = "Data channel listen request for device: " + *device_str + "\n";
            OutputDebugStringA(debug_msg.c_str());
            
            // Always start data listening if device is connected (like Android)
            if (connected_sockets_.find(*device_str) != connected_sockets_.end()) {
              StartDataListening(*device_str);
              OutputDebugStringA("Data listening started for device\n");
              result->Success(flutter::EncodableValue(true));
              return;
            } else {
              OutputDebugStringA("Device not connected for data listening\n");
              result->Success(flutter::EncodableValue(false));
              return;
            }
          }
        }
      }
    }
    // Default listen behavior for other channels
    result->Success(flutter::EncodableValue(true));
  } else if (method.compare("cancel") == 0) {
    CancelDataChannel(method_call.arguments());
    result->Success(flutter::EncodableValue(true));
  } else if (method.compare("close") == 0) {
    CloseDataChannel(method_call.arguments());
    result->Success(flutter::EncodableValue(true));
  }
  
  // State channel methods
  else if (method.compare("isAvailable") == 0) {
    result->Success(flutter::EncodableValue(IsBluetoothAvailable()));
  } else if (method.compare("isEnabled") == 0) {
    result->Success(flutter::EncodableValue(IsBluetoothEnabled()));
  } 
  
  // Connection channel methods
  else if (method.compare("isBluetoothSupported") == 0) {
    result->Success(flutter::EncodableValue(IsBluetoothAvailable()));
  } else if (method.compare("isBluetoothEnabled") == 0) {
    result->Success(flutter::EncodableValue(IsBluetoothEnabled()));
  } else if (method.compare("requestEnable") == 0) {
    result->Success(flutter::EncodableValue(false));
  } else if (method.compare("openSettings") == 0) {
    OpenBluetoothSettings();
    result->Success(flutter::EncodableValue(true));
  } else if (method.compare("getPairedDevices") == 0) {
    auto devices = GetPairedDevices();
    result->Success(flutter::EncodableValue(devices));
  } else if (method.compare("startDiscovery") == 0) {
    auto devices = StartDiscovery();
    result->Success(flutter::EncodableValue(devices));
  } else if (method.compare("stopDiscovery") == 0) {
    result->Success(flutter::EncodableValue(true));
  } else if (method.compare("isDiscovering") == 0) {
    result->Success(flutter::EncodableValue(false));
  }
  
  // Main channel methods
  else if (method.compare("connect") == 0) {
    OutputDebugStringA("HandleMethodCall: Connect method called\n");
    bool success = ConnectToDevice(method_call.arguments());
    if (success) {
      OutputDebugStringA("HandleMethodCall: Connection successful, notifying state change\n");
      NotifyConnectionStateChange(method_call.arguments(), true);
      
      // Don't auto-start data listening here - let Flutter app call listen when ready
      OutputDebugStringA("Connection established, waiting for data channel listen request\n");
    } else {
      OutputDebugStringA("HandleMethodCall: Connection failed\n");
    }
    result->Success(flutter::EncodableValue(success));
  } else if (method.compare("disconnect") == 0) {
    bool success = DisconnectDevice(method_call.arguments());
    // Send disconnection state change event and cleanup data channels
    if (success) {
      NotifyConnectionStateChange(method_call.arguments(), false);
      CleanupDataChannels(method_call.arguments());
    }
    result->Success(flutter::EncodableValue(success));
  } else if (method.compare("isConnected") == 0) {
    bool connected = IsDeviceConnected(method_call.arguments());
    result->Success(flutter::EncodableValue(connected));
  }
  
  // Data channel methods
  else if (method.compare("writeData") == 0) {
    bool success = WriteData(method_call.arguments());
    result->Success(flutter::EncodableValue(success));
  } else if (method.compare("readData") == 0) {
    std::string data = ReadData(method_call.arguments());
    result->Success(flutter::EncodableValue(data));
  } else if (method.compare("available") == 0) {
    int available = GetAvailableBytes(method_call.arguments());
    result->Success(flutter::EncodableValue(available));
  } else if (method.compare("flush") == 0) {
    bool success = FlushData(method_call.arguments());
    result->Success(flutter::EncodableValue(success));
  } 
  
  // Generic methods that might be called on any channel
  else if (method.compare("destroy") == 0) {
    result->Success(flutter::EncodableValue(true));
  } else if (method.compare("finish") == 0) {
    result->Success(flutter::EncodableValue(true));
  } else if (method.compare("getPlatformVersion") == 0) {
    result->Success(flutter::EncodableValue("Windows"));
  }
  
  else {
    result->NotImplemented();
  }
}

bool FlutterBluetoothClassicPlugin::IsBluetoothAvailable() {
  BLUETOOTH_FIND_RADIO_PARAMS params = { sizeof(BLUETOOTH_FIND_RADIO_PARAMS) };
  HANDLE hRadio;
  HBLUETOOTH_RADIO_FIND hFind = BluetoothFindFirstRadio(&params, &hRadio);
  
  if (hFind != NULL) {
    CloseHandle(hRadio);
    BluetoothFindRadioClose(hFind);
    return true;
  }
  return false;
}

bool FlutterBluetoothClassicPlugin::IsBluetoothEnabled() {
  BLUETOOTH_FIND_RADIO_PARAMS params = { sizeof(BLUETOOTH_FIND_RADIO_PARAMS) };
  HANDLE hRadio;
  HBLUETOOTH_RADIO_FIND hFind = BluetoothFindFirstRadio(&params, &hRadio);
  
  if (hFind != NULL) {
    BLUETOOTH_RADIO_INFO radioInfo = { sizeof(BLUETOOTH_RADIO_INFO) };
    DWORD result = BluetoothGetRadioInfo(hRadio, &radioInfo);
    CloseHandle(hRadio);
    BluetoothFindRadioClose(hFind);
    
    return (result == ERROR_SUCCESS);
  }
  return false;
}

void FlutterBluetoothClassicPlugin::OpenBluetoothSettings() {
  ShellExecute(NULL, L"open", L"ms-settings:bluetooth", NULL, NULL, SW_SHOWNORMAL);
}

flutter::EncodableList FlutterBluetoothClassicPlugin::GetPairedDevices() {
  flutter::EncodableList devices;
  
  BLUETOOTH_DEVICE_SEARCH_PARAMS searchParams = { 0 };
  searchParams.dwSize = sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS);
  searchParams.fReturnAuthenticated = TRUE;
  searchParams.fReturnRemembered = TRUE;
  searchParams.fReturnConnected = TRUE;
  searchParams.fReturnUnknown = FALSE;
  searchParams.fIssueInquiry = FALSE;
  searchParams.cTimeoutMultiplier = 1;
  
  BLUETOOTH_DEVICE_INFO deviceInfo = { 0 };
  deviceInfo.dwSize = sizeof(BLUETOOTH_DEVICE_INFO);
  
  HBLUETOOTH_DEVICE_FIND hFind = BluetoothFindFirstDevice(&searchParams, &deviceInfo);
  
  if (hFind != NULL) {
    do {
      flutter::EncodableMap device;
      
      // Convert wide string to UTF-8 properly
      std::wstring wname(deviceInfo.szName);
      int len = WideCharToMultiByte(CP_UTF8, 0, wname.c_str(), -1, NULL, 0, NULL, NULL);
      std::string name(len - 1, 0);
      WideCharToMultiByte(CP_UTF8, 0, wname.c_str(), -1, &name[0], len, NULL, NULL);
      
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
      device[flutter::EncodableValue("type")] = flutter::EncodableValue("classic");
      device[flutter::EncodableValue("isConnected")] = flutter::EncodableValue(deviceInfo.fConnected == TRUE);
      
      devices.push_back(flutter::EncodableValue(device));
      
    } while (BluetoothFindNextDevice(hFind, &deviceInfo));
    
    BluetoothFindDeviceClose(hFind);
  }
  
  return devices;
}

flutter::EncodableList FlutterBluetoothClassicPlugin::StartDiscovery() {
  flutter::EncodableList devices;
  
  BLUETOOTH_DEVICE_SEARCH_PARAMS searchParams = { 0 };
  searchParams.dwSize = sizeof(BLUETOOTH_DEVICE_SEARCH_PARAMS);
  searchParams.fReturnAuthenticated = TRUE;
  searchParams.fReturnRemembered = TRUE;
  searchParams.fReturnConnected = TRUE;
  searchParams.fReturnUnknown = TRUE;
  searchParams.fIssueInquiry = TRUE;
  searchParams.cTimeoutMultiplier = 2;
  
  BLUETOOTH_DEVICE_INFO deviceInfo = { 0 };
  deviceInfo.dwSize = sizeof(BLUETOOTH_DEVICE_INFO);
  
  HBLUETOOTH_DEVICE_FIND hFind = BluetoothFindFirstDevice(&searchParams, &deviceInfo);
  
  if (hFind != NULL) {
    do {
      flutter::EncodableMap device;
      
      // Convert wide string to UTF-8 properly
      std::wstring wname(deviceInfo.szName);
      int len = WideCharToMultiByte(CP_UTF8, 0, wname.c_str(), -1, NULL, 0, NULL, NULL);
      std::string name(len - 1, 0);
      WideCharToMultiByte(CP_UTF8, 0, wname.c_str(), -1, &name[0], len, NULL, NULL);
      
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
      device[flutter::EncodableValue("type")] = flutter::EncodableValue("classic");
      device[flutter::EncodableValue("isConnected")] = flutter::EncodableValue(deviceInfo.fConnected == TRUE);
      
      devices.push_back(flutter::EncodableValue(device));
      
    } while (BluetoothFindNextDevice(hFind, &deviceInfo));
    
    BluetoothFindDeviceClose(hFind);
  }
  
  return devices;
}

flutter::EncodableList FlutterBluetoothClassicPlugin::GetConnectedDevices() {
  flutter::EncodableList devices;
  
  for (const auto& pair : connected_sockets_) {
    flutter::EncodableMap device;
    device[flutter::EncodableValue("address")] = flutter::EncodableValue(pair.first);
    device[flutter::EncodableValue("name")] = flutter::EncodableValue("Connected Device");
    device[flutter::EncodableValue("type")] = flutter::EncodableValue("classic");
    device[flutter::EncodableValue("isConnected")] = flutter::EncodableValue(true);
    
    devices.push_back(flutter::EncodableValue(device));
  }
  
  return devices;
}

bool FlutterBluetoothClassicPlugin::ConnectToDevice(const flutter::EncodableValue* arguments) {
  if (!arguments) {
    OutputDebugStringA("ConnectToDevice: No arguments provided\n");
    return false;
  }
  
  const auto* args = std::get_if<flutter::EncodableMap>(arguments);
  if (!args) {
    OutputDebugStringA("ConnectToDevice: Invalid arguments format\n");
    return false;
  }
  
  auto address_it = args->find(flutter::EncodableValue("address"));
  if (address_it == args->end()) {
    OutputDebugStringA("ConnectToDevice: No address provided\n");
    return false;
  }
  
  const auto* address_str = std::get_if<std::string>(&address_it->second);
  if (!address_str) {
    OutputDebugStringA("ConnectToDevice: Invalid address format\n");
    return false;
  }
  
  std::string debug_msg = "ConnectToDevice: Attempting to connect to " + *address_str + "\n";
  OutputDebugStringA(debug_msg.c_str());
  
  // Check if already connected
  if (connected_sockets_.find(*address_str) != connected_sockets_.end()) {
    OutputDebugStringA("ConnectToDevice: Device already connected\n");
    return true;
  }
  
  // Initialize Winsock
  WSADATA wsaData;
  int wsaResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
  if (wsaResult != 0) {
    OutputDebugStringA("ConnectToDevice: WSAStartup failed\n");
    return false;
  }
  
  // Parse MAC address (try different formats)
  BTH_ADDR btAddr = 0;
  int values[6];
  
  // Try format: XX:XX:XX:XX:XX:XX
  if (sscanf_s(address_str->c_str(), "%02x:%02x:%02x:%02x:%02x:%02x",
               &values[0], &values[1], &values[2], &values[3], &values[4], &values[5]) == 6) {
    for (int i = 0; i < 6; ++i) {
      btAddr |= ((BTH_ADDR)values[5-i]) << (i * 8);
    }
  }
  // Try format: XX-XX-XX-XX-XX-XX  
  else if (sscanf_s(address_str->c_str(), "%02x-%02x-%02x-%02x-%02x-%02x",
                    &values[0], &values[1], &values[2], &values[3], &values[4], &values[5]) == 6) {
    for (int i = 0; i < 6; ++i) {
      btAddr |= ((BTH_ADDR)values[5-i]) << (i * 8);
    }
  }
  // Try format: XXXXXXXXXXXX
  else if (address_str->length() == 12) {
    for (int i = 0; i < 6; ++i) {
      std::string byte_str = address_str->substr(i * 2, 2);
      values[i] = std::stoi(byte_str, nullptr, 16);
      btAddr |= ((BTH_ADDR)values[5-i]) << (i * 8);
    }
  }
  else {
    OutputDebugStringA("ConnectToDevice: Invalid MAC address format\n");
    return false;
  }
  
  OutputDebugStringA("ConnectToDevice: MAC address parsed successfully\n");
  
  // Create socket
  SOCKET sock = socket(AF_BTH, SOCK_STREAM, BTHPROTO_RFCOMM);
  if (sock == INVALID_SOCKET) {
    int error = WSAGetLastError();
    char error_msg[256];
    sprintf_s(error_msg, "ConnectToDevice: Socket creation failed with error %d\n", error);
    OutputDebugStringA(error_msg);
    WSACleanup();
    return false;
  }
  
  OutputDebugStringA("ConnectToDevice: Socket created successfully\n");
  
  // Set up connection address
  SOCKADDR_BTH sockAddr = { 0 };
  sockAddr.addressFamily = AF_BTH;
  sockAddr.btAddr = btAddr;
  sockAddr.port = BT_PORT_ANY; // Try common RFCOMM port
  
  // Try connecting to different RFCOMM channels (1-30)
  bool connected = false;
  for (int channel = 1; channel <= 30 && !connected; ++channel) {
    sockAddr.port = channel;
    
    char channel_msg[256];
    sprintf_s(channel_msg, "ConnectToDevice: Trying RFCOMM channel %d\n", channel);
    OutputDebugStringA(channel_msg);
    
    int result = connect(sock, (SOCKADDR*)&sockAddr, sizeof(sockAddr));
    if (result == 0) {
      connected = true;
      char success_msg[256];
      sprintf_s(success_msg, "ConnectToDevice: Connected successfully on channel %d\n", channel);
      OutputDebugStringA(success_msg);
      break;
    } else {
      int error = WSAGetLastError();
      if (error != WSAECONNREFUSED && error != WSAETIMEDOUT) {
        // Only log non-connection errors
        char error_msg[256];
        sprintf_s(error_msg, "ConnectToDevice: Channel %d failed with error %d\n", channel, error);
        OutputDebugStringA(error_msg);
      }
    }
  }
  
  if (!connected) {
    OutputDebugStringA("ConnectToDevice: Failed to connect on any RFCOMM channel\n");
    closesocket(sock);
    WSACleanup();
    return false;
  }
  
  // Store successful connection
  connected_sockets_[*address_str] = sock;
  OutputDebugStringA("ConnectToDevice: Connection stored successfully\n");
  
  return true;
}

bool FlutterBluetoothClassicPlugin::DisconnectDevice(const flutter::EncodableValue* arguments) {
  if (!arguments) {
    // Disconnect all devices
    for (auto& pair : connected_sockets_) {
      closesocket(pair.second);
    }
    connected_sockets_.clear();
    return true;
  }
  
  const auto* args = std::get_if<flutter::EncodableMap>(arguments);
  if (!args) return false;
  
  auto address_it = args->find(flutter::EncodableValue("address"));
  if (address_it == args->end()) return false;
  
  const auto* address_str = std::get_if<std::string>(&address_it->second);
  if (!address_str) return false;
  
  auto sock_it = connected_sockets_.find(*address_str);
  if (sock_it != connected_sockets_.end()) {
    closesocket(sock_it->second);
    connected_sockets_.erase(sock_it);
    return true;
  }
  
  return true; // Return true even if not found (already disconnected)
}

bool FlutterBluetoothClassicPlugin::IsDeviceConnected(const flutter::EncodableValue* arguments) {
  if (!arguments) return false;
  
  const auto* args = std::get_if<flutter::EncodableMap>(arguments);
  if (!args) return false;
  
  auto address_it = args->find(flutter::EncodableValue("address"));
  if (address_it == args->end()) return false;
  
  const auto* address_str = std::get_if<std::string>(&address_it->second);
  if (!address_str) return false;
  
  return connected_sockets_.find(*address_str) != connected_sockets_.end();
}

void FlutterBluetoothClassicPlugin::NotifyConnectionStateChange(const flutter::EncodableValue* arguments, bool connected) {
  // This would typically send an event through a method channel
  // For now, we'll just update internal state
  // In a full implementation, you'd need to store channel references to send events
}

void FlutterBluetoothClassicPlugin::StartDataListening(const std::string& device_address) {
  std::string debug_msg = "StartDataListening called for: " + device_address + "\n";
  OutputDebugStringA(debug_msg.c_str());
  
  // Check if already listening for this device
  if (listening_devices_.find(device_address) != listening_devices_.end()) {
    OutputDebugStringA("Data listening already active for device\n");
    return;
  }
  
  auto sock_it = connected_sockets_.find(device_address);
  if (sock_it == connected_sockets_.end()) {
    OutputDebugStringA("Cannot start data listening - device not connected\n");
    return;
  }
  
  SOCKET sock = sock_it->second;
  
  // Set socket to non-blocking mode for polling
  u_long mode = 1;
  ioctlsocket(sock, FIONBIO, &mode);
  
  // Store device for data monitoring
  listening_devices_.insert(device_address);
  
  // Clear any existing data buffer for fresh start
  {
    std::lock_guard<std::mutex> lock(data_mutex_);
    received_data_[device_address].clear();
  }
  
  // Start background thread for data monitoring
  std::thread data_thread([this, device_address, sock]() {
    this->DataListeningThread(device_address, sock);
  });
  data_thread.detach();
  
  OutputDebugStringA("Data listening thread started for device\n");
}

void FlutterBluetoothClassicPlugin::DataListeningThread(const std::string& device_address, SOCKET sock) {
  char buffer[1024];
  
  std::string thread_debug_msg = "DataListeningThread: Started for device: " + device_address + "\n";
  OutputDebugStringA(thread_debug_msg.c_str());
  
  while (listening_devices_.find(device_address) != listening_devices_.end() && 
         connected_sockets_.find(device_address) != connected_sockets_.end()) {
    
    int bytes_received = recv(sock, buffer, sizeof(buffer), 0);
    
    if (bytes_received > 0) {
      // Store raw received data WITHOUT any modifications (like Android)
      {
        std::lock_guard<std::mutex> lock(data_mutex_);
        received_data_[device_address].append(buffer, bytes_received);
      }
      
      // Debug: Log received data in detail
      std::string recv_debug_msg = "Received " + std::to_string(bytes_received) + " bytes from " + device_address + ": ";
      int max_chars = bytes_received < 50 ? bytes_received : 50;
      for (int j = 0; j < max_chars; j++) {
        if (buffer[j] >= 32 && buffer[j] <= 126) {
          recv_debug_msg += buffer[j];
        } else {
          recv_debug_msg += "[" + std::to_string((unsigned char)buffer[j]) + "]";
        }
      }
      if (bytes_received > 50) recv_debug_msg += "...";
      recv_debug_msg += "\n";
      OutputDebugStringA(recv_debug_msg.c_str());
      
    } else if (bytes_received == 0) {
      OutputDebugStringA("DataListeningThread: Connection closed by remote device\n");
      break;
    } else {
      int error = WSAGetLastError();
      if (error != WSAEWOULDBLOCK) {
        char error_msg[256];
        sprintf_s(error_msg, "DataListeningThread: Receive error: %d\n", error);
        OutputDebugStringA(error_msg);
        break;
      }
    }
    
    // Use same delay as Android (10ms)
    Sleep(10);
  }
  
  OutputDebugStringA("DataListeningThread: Ending for device\n");
  listening_devices_.erase(device_address);
}

std::string FlutterBluetoothClassicPlugin::ReadData(const flutter::EncodableValue* arguments) {
  if (!arguments) return "";
  
  const auto* args = std::get_if<flutter::EncodableMap>(arguments);
  if (!args) return "";
  
  auto address_it = args->find(flutter::EncodableValue("address"));
  if (address_it == args->end()) return "";
  
  const auto* address_str = std::get_if<std::string>(&address_it->second);
  if (!address_str) return "";
  
  std::lock_guard<std::mutex> lock(data_mutex_);
  auto data_it = received_data_.find(*address_str);
  if (data_it != received_data_.end()) {
    std::string data = data_it->second;
    if (!data.empty()) {
      data_it->second.clear(); // Clear after reading
      
      // Debug: Log what's being returned to Flutter
      std::string read_debug_msg = "ReadData returning " + std::to_string(data.length()) + " bytes: ";
      size_t max_chars = data.length() < 50 ? data.length() : 50;
      for (size_t k = 0; k < max_chars; k++) {
        if (data[k] >= 32 && data[k] <= 126) {
          read_debug_msg += data[k];
        } else {
          read_debug_msg += "[" + std::to_string((unsigned char)data[k]) + "]";
        }
      }
      if (data.length() > 50) read_debug_msg += "...";
      read_debug_msg += "\n";
      OutputDebugStringA(read_debug_msg.c_str());
      
      // Return raw data exactly as received - no processing
      return data;
    }
  }
  
  return "";
}

int FlutterBluetoothClassicPlugin::GetAvailableBytes(const flutter::EncodableValue* arguments) {
  if (!arguments) return 0;
  
  const auto* args = std::get_if<flutter::EncodableMap>(arguments);
  if (!args) return 0;
  
  auto address_it = args->find(flutter::EncodableValue("address"));
  if (address_it == args->end()) return 0;
  
  const auto* address_str = std::get_if<std::string>(&address_it->second);
  if (!address_str) return 0;
  
  std::lock_guard<std::mutex> lock(data_mutex_);
  auto data_it = received_data_.find(*address_str);
  if (data_it != received_data_.end()) {
    int available = (int)data_it->second.length();
    if (available > 0) {
      std::string debug_msg = "GetAvailableBytes: " + std::to_string(available) + " bytes available\n";
      OutputDebugStringA(debug_msg.c_str());
    }
    return available;
  }
  
  return 0;
}

bool FlutterBluetoothClassicPlugin::FlushData(const flutter::EncodableValue* arguments) {
  if (!arguments) return false;
  
  const auto* args = std::get_if<flutter::EncodableMap>(arguments);
  if (!args) return false;
  
  auto address_it = args->find(flutter::EncodableValue("address"));
  if (address_it == args->end()) return false;
  
  const auto* address_str = std::get_if<std::string>(&address_it->second);
  if (!address_str) return false;
  
  std::lock_guard<std::mutex> lock(data_mutex_);
  received_data_[*address_str].clear();
  return true;
}

bool FlutterBluetoothClassicPlugin::WriteData(const flutter::EncodableValue* arguments) {
  if (!arguments) return false;
  
  const auto* args = std::get_if<flutter::EncodableMap>(arguments);
  if (!args) return false;
  
  auto address_it = args->find(flutter::EncodableValue("address"));
  auto data_it = args->find(flutter::EncodableValue("data"));
  
  if (address_it == args->end() || data_it == args->end()) return false;
  
  const auto* address_str = std::get_if<std::string>(&address_it->second);
  
  if (!address_str) return false;
  
  auto sock_it = connected_sockets_.find(*address_str);
  if (sock_it == connected_sockets_.end()) return false;
  
  // Handle both string and binary data
  const char* data_ptr = nullptr;
  size_t data_len = 0;
  
  if (const auto* data_str = std::get_if<std::string>(&data_it->second)) {
    data_ptr = data_str->c_str();
    data_len = data_str->length();
  } else if (const auto* data_list = std::get_if<flutter::EncodableList>(&data_it->second)) {
    // Handle binary data as list of bytes
    static std::vector<char> byte_buffer;
    byte_buffer.clear();
    byte_buffer.reserve(data_list->size());
    
    for (const auto& byte_val : *data_list) {
      if (const auto* byte_int = std::get_if<int>(&byte_val)) {
        byte_buffer.push_back(static_cast<char>(*byte_int));
      }
    }
    
    data_ptr = byte_buffer.data();
    data_len = byte_buffer.size();
  }
  
  if (data_ptr && data_len > 0) {
    int bytes_sent = send(sock_it->second, data_ptr, (int)data_len, 0);
    if (bytes_sent > 0) {
      std::string debug_msg = "WriteData: Sent " + std::to_string(bytes_sent) + " bytes to " + *address_str + "\n";
      OutputDebugStringA(debug_msg.c_str());
      return true;
    }
  }
  
  return false;
}

void FlutterBluetoothClassicPlugin::CleanupDataChannels(const flutter::EncodableValue* arguments) {
  if (arguments) {
    const auto* args = std::get_if<flutter::EncodableMap>(arguments);
    if (args) {
      auto address_it = args->find(flutter::EncodableValue("address"));
      if (address_it != args->end()) {
        const auto* address_str = std::get_if<std::string>(&address_it->second);
        if (address_str) {
          // Stop data listening for this device
          listening_devices_.erase(*address_str);
          
          // Clear buffered data
          std::lock_guard<std::mutex> lock(data_mutex_);
          received_data_.erase(*address_str);
          
          OutputDebugStringA("CleanupDataChannels: Cleaned up data channels\n");
        }
      }
    }
  } else {
    // Clean up all data channels if no specific device
    listening_devices_.clear();
    std::lock_guard<std::mutex> lock(data_mutex_);
    received_data_.clear();
    OutputDebugStringA("CleanupDataChannels: Cleaned up all data channels\n");
  }
}

void FlutterBluetoothClassicPlugin::CancelDataChannel(const flutter::EncodableValue* arguments) {
  if (arguments) {
    const auto* args = std::get_if<flutter::EncodableMap>(arguments);
    if (args) {
      auto address_it = args->find(flutter::EncodableValue("address"));
      if (address_it != args->end()) {
        const auto* address_str = std::get_if<std::string>(&address_it->second);
        if (address_str) {
          // Stop listening for this device
          listening_devices_.erase(*address_str);
          OutputDebugStringA("CancelDataChannel: Cancelled data channel\n");
        }
      }
    }
  }
}

void FlutterBluetoothClassicPlugin::CloseDataChannel(const flutter::EncodableValue* arguments) {
  if (arguments) {
    const auto* args = std::get_if<flutter::EncodableMap>(arguments);
    if (args) {
      auto address_it = args->find(flutter::EncodableValue("address"));
      if (address_it != args->end()) {
        const auto* address_str = std::get_if<std::string>(&address_it->second);
        if (address_str) {
          // Stop listening and clear data
          listening_devices_.erase(*address_str);
          
          std::lock_guard<std::mutex> lock(data_mutex_);
          received_data_.erase(*address_str);
          
          OutputDebugStringA("CloseDataChannel: Closed data channel\n");
        }
      }
    }
  }
}

}  // namespace flutter_bluetooth_classic
