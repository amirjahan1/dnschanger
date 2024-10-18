import 'package:flutter/material.dart';
import '../../data/dns_data.dart';
import '../../models/dns_model.dart';
import '../../services/dns_service.dart';
import '../../main.dart'; // Import your main file for MethodChannel

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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Connect/Disconnect button
                  IconButton(
                    icon: Icon(
                      isActive ? Icons.power_off : Icons.wifi, // Change icon based on active state
                      color: isActive ? Colors.green : null, // Change color based on active state
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
                ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connected to: ${dns.ipAddress.join(', ')}"),
        ),
      );
    } on Exception catch (e) {
      print("Failed to set DNS: $e");
    }
  }

  // Function to disconnect the current DNS
  Future<void> disconnectDNS() async {
    try {
      // Call the platform method to disconnect VPN
      await DNSChangerApp.disconnectVPN();
      setState(() {
        activeDNSIndex = null; // No DNS is active now
      });
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