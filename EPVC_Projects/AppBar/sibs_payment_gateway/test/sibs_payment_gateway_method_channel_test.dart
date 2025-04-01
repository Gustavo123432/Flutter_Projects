import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibs_payment_gateway/sibs_payment_gateway_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelSibsPaymentGateway platform = MethodChannelSibsPaymentGateway();
  const MethodChannel channel = MethodChannel('sibs_payment_gateway');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
