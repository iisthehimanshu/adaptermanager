import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'adapter_manager_platform_interface.dart';

/// An implementation of [AdapterManagerPlatform] that uses method channels.
class MethodChannelAdapterManager extends AdapterManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('adapter_manager');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
