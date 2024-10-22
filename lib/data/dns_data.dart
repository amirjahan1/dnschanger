import 'package:dnschanger/models/dns_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DNSdata {
  static List<DNSModel> defaultDNS = [
      DNSModel(name: 'Shekan', ipAddress: ["178.22.122.100", "185.51.200.2"]),
      DNSModel(name: 'Elctro', ipAddress: ["78.157.42.100", "78.157.42.101"]),
      DNSModel(name: 'Radar', ipAddress:  ["10.202.10.10", "10.202.10.11"]),
      DNSModel(name: '403 online', ipAddress: ["10.202.10.102", "10.202.10.202"]),
      DNSModel(name: 'Cloudflare', ipAddress: ["1.1.1.1", "1.0.0.1"]),
      DNSModel(name: 'Google', ipAddress: ["8.8.8.8", "8.8.4.4"]),
      DNSModel(name: 'Yandex', ipAddress: ["77.88.8.8", "77.88.8.1"]),
    ];
   static List<DNSModel> customDNS = [];

   static Future<List<DNSModel>> getAllDNS() async {
    await loadCustomDNS();
    return [...defaultDNS, ...customDNS];
}

// Load custom DNS entries from SharedPreferences
  static Future<void> loadCustomDNS() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? customDNSJson = prefs.getString('customDNS');
    if (customDNSJson != null) {
      List<dynamic> jsonList = json.decode(customDNSJson);
      customDNS = jsonList.map((jsonItem) => DNSModel.fromMap(jsonItem)).toList();
    } else {
      customDNS = [];
    }
  }

  // Save custom DNS entries to SharedPreferences
  static Future<void> saveCustomDNS() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> jsonList = customDNS.map((dns) => dns.toMap()).toList();
    String jsonString = json.encode(jsonList);
    await prefs.setString('customDNS', jsonString);
  }

  // Add a custom DNS entry
  static Future<void> addCustomDNS(DNSModel dns) async {
    customDNS.add(dns);
    await saveCustomDNS();
  }

  // Update a custom DNS entry
  static Future<void> updateCustomDNS(int index, DNSModel dns) async {
    if (index >= 0 && index < customDNS.length) {
      customDNS[index] = dns;
      await saveCustomDNS();
    }
  }

  // Delete a custom DNS entry
  static Future<void> deleteCustomDNS(int index) async {
    if (index >= 0 && index < customDNS.length) {
      customDNS.removeAt(index);
      await saveCustomDNS();
    }
  }
}
