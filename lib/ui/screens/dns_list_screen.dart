import 'package:flutter/material.dart';
import '../../data/dns_data.dart';
import '../../models/dns_model.dart';
import '../../services/dns_service.dart';
import '../../main.dart'; // Import your main file for MethodChannel
import 'package:awesome_notifications/awesome_notifications.dart';

class DNSListScreen extends StatefulWidget {
  @override
  _DNSListScreenState createState() => _DNSListScreenState();
}

class _DNSListScreenState extends State<DNSListScreen> {
  late DNSService dnsService;
  int? activeDNSIndex; // Variable to track which DNS is currently active

  @override
  void initState() {
    super.initState();
    dnsService = DNSService();
    activeDNSIndex = null; // Initially, no DNS is active

    // Request permissions if needed
    requestNotificationPermissions();
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
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'DISCONNECT_DNS',
          label: 'Disconnect',
          autoDismissible: false,
          actionType: ActionType.KeepOnTop,
        ),
      ],
    );
  }

  // Function to disconnect the current DNS
  Future<void> disconnectDNS() async {
    try {
      // Call the platform method to disconnect VPN
      await DNSChangerApp.disconnectVPN();
      setState(() {
        activeDNSIndex = null; // No DNS is active now
      });

      // Cancel the notification
      await AwesomeNotifications().cancel(0);

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
