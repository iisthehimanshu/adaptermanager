import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'adapter_manager_method_channel.dart';

abstract class AdapterManagerPlatform extends PlatformInterface {
  /// Constructs a AdapterManagerPlatform.
  AdapterManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdapterManagerPlatform _instance = MethodChannelAdapterManager();

  /// The default instance of [AdapterManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelAdapterManager].
  static AdapterManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AdapterManagerPlatform] when
  /// they register themselves.
  static set instance(AdapterManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
