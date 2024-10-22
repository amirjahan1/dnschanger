import 'package:flutter/material.dart';
import '../../data/dns_data.dart';
import '../../models/dns_model.dart';
import '../../services/dns_service.dart';
import '../../main.dart'; // Import your main file for MethodChannel
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DNSListScreen extends StatefulWidget {
  @override
  _DNSListScreenState createState() => _DNSListScreenState();
}

class _DNSListScreenState extends State<DNSListScreen> with WidgetsBindingObserver {
  late DNSService dnsService;
  int? activeDNSIndex; // Variable to track which DNS is currently active

  @override
  void initState() {
    super.initState();
    dnsService = DNSService();
    activeDNSIndex = null; // Initially, no DNS is active

    // Add observer
    WidgetsBinding.instance.addObserver(this);

    // Request permissions if needed
    requestNotificationPermissions();

    // Check VPN state on startup
    checkVpnState();
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Listen for app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has resumed, check VPN state
      checkVpnState();
    }
  }

  Future<void> checkVpnState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool vpnConnected = prefs.getBool('vpnConnected') ?? false;

    if (vpnConnected) {
      int index = prefs.getInt('activeDNSIndex') ?? -1;
      if (index >= 0 && index < DNSdata.getAllDNS().length) {
        setState(() {
          activeDNSIndex = index;
        });
      }
    } else {
      setState(() {
        activeDNSIndex = null;
      });
    }
  }

  Future<void> requestNotificationPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // You can show a dialog here before requesting permission
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dnsList = DNSdata.getAllDNS();
    return Scaffold(
      appBar: AppBar(title: Text("DNS Changer")),
      body: ListView.builder(
        itemCount: dnsList.length,
        itemBuilder: (context, index) {
          final dns = dnsList[index];
          final isActive = activeDNSIndex == index; // Check if this DNS is active
          return Card(
            child: ListTile(
              title: Text(dns.name),
              subtitle: Text(dns.ipAddress.join(", ")),
              trailing: IconButton(
                icon: Icon(
                  isActive ? Icons.power_off : Icons.wifi,
                  color: isActive ? Colors.green : null,
                ),
                onPressed: () async {
                  if (isActive) {
                    // If active, disconnect
                    await disconnectDNS();
                  } else {
                    // Connect to this DNS
                    await connectDNS(dns, index);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Function to connect to a DNS
  Future<void> connectDNS(DNSModel dns, int index) async {
    try {
      // Call the platform method to set DNS
      await DNSChangerApp.setDNS(dns.ipAddress);

      // Store the connection state
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vpnConnected', true);
      await prefs.setInt('activeDNSIndex', index);

      setState(() {
        activeDNSIndex = index; // Set the active DNS index
      });

      // Show notification with disconnect action
      await showDisconnectNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connected to: ${dns.ipAddress.join(', ')}"),
        ),
      );
    } on Exception catch (e) {
      print("Failed to set DNS: $e");
    }
  }

  Future<void> showDisconnectNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'dns_disconnect_channel',
        title: 'DNS Connected',
        body: 'Tap to disconnect',
        notificationLayout: NotificationLayout.Default,
        locked: true, // Notification cannot be swiped away
        autoDismissible: false,
        badge: 1, // Set the badge count to 1
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISCONNECT_DNS',
          label: 'Disconnect',
          autoDismissible: false,
          actionType: ActionType.KeepOnTop, // Brings app to foreground
        ),
      ],
    );
  }

  // Function to disconnect the current DNS
  Future<void> disconnectDNS() async {
    try {
      // Call the platform method to disconnect VPN
      await DNSChangerApp.disconnectVPN();

      // Store the connection state
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vpnConnected', false);
      await prefs.remove('activeDNSIndex');

      setState(() {
        activeDNSIndex = null; // No DNS is active now
      });

      // Cancel the notification
      await AwesomeNotifications().cancel(0);

      // Reset the badge count to 0
      await AwesomeNotifications().resetGlobalBadge();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Disconnected from DNS"),
        ),
      );
    } on Exception catch (e) {
      print("Failed to disconnect DNS: $e");
    }
  }
}
