import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/dns_list_screen.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Awesome Notifications
  AwesomeNotifications().initialize(
    null, // Use default icon or specify your own
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
    debug: true, // Set to false in production
  );

  // Set up global notification listeners
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
  );

  runApp(DNSChangerApp());
}

// Define the action handler
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  if (receivedAction.buttonKeyPressed == 'DISCONNECT_DNS') {
    // Handle the action here
    await DNSChangerApp.disconnectVPN();
    // Cancel the notification
    if (receivedAction.id != null) {
      await AwesomeNotifications().cancel(receivedAction.id!);
    }
  }
}

class DNSChangerApp extends StatelessWidget {
  // Define a method channel
  static const platform = MethodChannel('com.example.dnschanger/dns');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DNS Changer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DNSListScreen(), // Your DNS list screen
    );
  }

  // Function to set DNS through the MethodChannel
  static Future<void> setDNS(List<String> dns) async {
    try {
      await platform.invokeMethod('setDNS', {"dns": dns});
    } on PlatformException catch (e) {
      print("Failed to set DNS: ${e.message}");
    }
  }

  // Function to disconnect VPN through the MethodChannel
  static Future<void> disconnectVPN() async {
    try {
      await platform.invokeMethod('disconnectVPN');
    } on PlatformException catch (e) {
      print("Failed to disconnect VPN: ${e.message}");
    }
  }
}
