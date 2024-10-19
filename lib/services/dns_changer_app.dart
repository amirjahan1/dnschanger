import 'dart:async';
import 'package:flutter/services.dart';

class DNSChangerApp {
  static const platform = MethodChannel('com.example.dnschanger/dns');
  static const eventChannel = EventChannel('com.example.dnschanger/vpnStatus');

  static Future<void> setDNS(List<String> dns) async {
    await platform.invokeMethod('setDNS', {'dns': dns});
  }

  static Future<void> disconnectVPN() async {
    await platform.invokeMethod('disconnectVPN');
  }

  static Future<bool> isVpnActive() async {
    final bool isActive = await platform.invokeMethod('isVpnActive');
    return isActive;
  }

  static Stream<bool> get vpnStatusStream {
    return eventChannel.receiveBroadcastStream().map((event) => event as bool);
  }
}
