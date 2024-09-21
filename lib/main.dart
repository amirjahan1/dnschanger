import 'package:flutter/material.dart';
import 'ui/screens/dns_list_screen.dart';  // Import the DNSListScreen

void main() {
  runApp(DNSChangerApp());
}

class DNSChangerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DNS Changer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DNSListScreen(),  // Call your DNSListScreen here
    );
  }
}
