import 'package:flutter/material.dart';
import '../../data/dns_data.dart';
import '../../services/dns_service.dart';

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
                icon: Icon(Icons.ping),
                onPressed: () async {
                  final pingTime = await dnsService.pingDNS(dns.ipAddress[0]);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Ping: $pingTime ms")),
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
