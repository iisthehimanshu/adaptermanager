import 'package:flutter_test/flutter_test.dart';
import 'package:adapter_manager/adapter_manager.dart';
import 'package:adapter_manager/adapter_manager_platform_interface.dart';
import 'package:adapter_manager/adapter_manager_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAdapterManagerPlatform
    with MockPlatformInterfaceMixin
    implements AdapterManagerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AdapterManagerPlatform initialPlatform = AdapterManagerPlatform.instance;

  test('$MethodChannelAdapterManager is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAdapterManager>());
  });

  test('getPlatformVersion', () async {
    AdapterManager adapterManagerPlugin = AdapterManager();
    MockAdapterManagerPlatform fakePlatform = MockAdapterManagerPlatform();
    AdapterManagerPlatform.instance = fakePlatform;

    expect("await adapterManagerPlugin.getPlatformVersion()", '42');
  });
}
