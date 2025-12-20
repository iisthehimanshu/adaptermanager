#include "include/adapter_manager/adapter_manager_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "adapter_manager_plugin.h"

void AdapterManagerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  adapter_manager::AdapterManagerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
