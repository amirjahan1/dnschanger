import 'package:flutter/material.dart';
import '../../data/dns_data.dart';
import '../../services/dns_service.dart';
import '../../main.dart'; // Import your main file for MethodChannel

class DNSListScreen extends StatefulWidget {
  @override
  _DNSListScreenState createState() => _DNSListScreenState();
}

class _DNSListScreenState extends State<DNSListScreen> {
  late DNSService dnsService;

  @override
  void initState() {
    super.initState();
    dnsService = DNSService();
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
          return Card(
            child: ListTile(
              title: Text(dns.name),
              subtitle: Text(dns.ipAddress.join(", ")),
              trailing: IconButton(
                icon: Icon(Icons.wifi),
                onPressed: () async {
                  print(dns.ipAddress);
                  // Call the platform method to set DNS
                  await DNSChangerApp.setDNS(dns.ipAddress);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "DNS changed to: ${dns.ipAddress.join(', ')}")),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
