import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sibs_payment_gateway_method_channel.dart';

abstract class SibsPaymentGatewayPlatform extends PlatformInterface {
  /// Constructs a SibsPaymentGatewayPlatform.
  SibsPaymentGatewayPlatform() : super(token: _token);

  static final Object _token = Object();

  static SibsPaymentGatewayPlatform _instance = MethodChannelSibsPaymentGateway();

  /// The default instance of [SibsPaymentGatewayPlatform] to use.
  ///
  /// Defaults to [MethodChannelSibsPaymentGateway].
  static SibsPaymentGatewayPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SibsPaymentGatewayPlatform] when
  /// they register themselves.
  static set instance(SibsPaymentGatewayPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
