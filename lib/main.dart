import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/dns_list_screen.dart'; // Your screen that shows the DNS list

void main() {
  runApp(DNSChangerApp());
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
}
