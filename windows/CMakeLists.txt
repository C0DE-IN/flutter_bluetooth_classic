# This file contains the CMake configuration for the Flutter Bluetooth Classic plugin.

cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "flutter_bluetooth_classic")
project(${PROJECT_NAME} LANGUAGES CXX)

# Compilation settings that should be applied to most targets.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100" /wd"4244" /wd"4267" /wd"4996" /wd"4018")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=0")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_bluetooth_classic_plugin")

add_library(${PLUGIN_NAME} SHARED
  "flutter_bluetooth_classic_plugin.cpp"
  "flutter_bluetooth_classic_plugin_c_api.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# Add Bluetooth libraries for Windows
target_link_libraries(${PLUGIN_NAME} PRIVATE
  bthprops
  ws2_32
  BluetoothApis
  Shell32
)

# List of absolute paths to libraries that should be bundled with the plugin
set(flutter_bluetooth_classic_bundled_libraries
  ""
  PARENT_SCOPE
)
