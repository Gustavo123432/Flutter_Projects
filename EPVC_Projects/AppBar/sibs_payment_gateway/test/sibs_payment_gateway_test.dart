import 'package:flutter_test/flutter_test.dart';
import 'package:sibs_payment_gateway/sibs_payment_gateway.dart';
import 'package:sibs_payment_gateway/sibs_payment_gateway_platform_interface.dart';
import 'package:sibs_payment_gateway/sibs_payment_gateway_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSibsPaymentGatewayPlatform
    with MockPlatformInterfaceMixin
    implements SibsPaymentGatewayPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SibsPaymentGatewayPlatform initialPlatform = SibsPaymentGatewayPlatform.instance;

  test('$MethodChannelSibsPaymentGateway is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSibsPaymentGateway>());
  });

  test('getPlatformVersion', () async {
    SibsPaymentGateway sibsPaymentGatewayPlugin = SibsPaymentGateway();
    MockSibsPaymentGatewayPlatform fakePlatform = MockSibsPaymentGatewayPlatform();
    SibsPaymentGatewayPlatform.instance = fakePlatform;

    expect(await sibsPaymentGatewayPlugin.getPlatformVersion(), '42');
  });
}
