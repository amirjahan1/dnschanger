// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/dns_list_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'dns_disconnect_channel',
        channelName: 'DNS Disconnect',
        channelDescription: 'Notification to disconnect DNS',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        locked: true,
      )
    ],
    debug: true,
  );

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );

  runApp(DNSChangerApp());
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  if (receivedAction.buttonKeyPressed == 'DISCONNECT_DNS') {
    await DNSChangerApp.disconnectVPN();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vpnConnected', false);
    await prefs.remove('activeDNSName');

    if (receivedAction.id != null) {
      await AwesomeNotifications().cancel(receivedAction.id!);
    }

    await AwesomeNotifications().resetGlobalBadge();
  }
}

class DNSChangerApp extends StatelessWidget {
  static const platform = MethodChannel('com.example.dnschanger/dns');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DNS Changer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DNSListScreen(),
    );
  }

  static Future<void> setDNS(List<String> dns) async {
    try {
      await platform.invokeMethod('setDNS', {"dns": dns});
    } on PlatformException catch (e) {
      print("Failed to set DNS: ${e.message}");
    }
  }

  static Future<void> disconnectVPN() async {
    try {
      await platform.invokeMethod('disconnectVPN');
    } on PlatformException catch (e) {
      print("Failed to disconnect VPN: ${e.message}");
    }
  }
}
