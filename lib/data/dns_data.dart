import 'package:dnschanger/models/dns_model.dart';

class DNSdata {
  static List<DNSModel> getAllDNS() {
    return [
      DNSModel(name: 'Shekan', ipAddress: ["178.22.122.100", "185.51.200.2"]),
      DNSModel(name: 'Elctro', ipAddress: ["78.157.42.100", "78.157.42.101"]),
      DNSModel(name: 'Radar', ipAddress:  ["10.202.10.10", "10.202.10.11"]),
      DNSModel(name: '403 online', ipAddress: ["10.202.10.102", "10.202.10.202"]),
      DNSModel(name: 'Cloudflare', ipAddress: ["1.1.1.1", "1.0.0.1"]),
      DNSModel(name: 'Google', ipAddress: ["8.8.8.8", "8.8.4.4"]),
      DNSModel(name: 'Yandex', ipAddress: ["77.88.8.8", "77.88.8.1"]),
    ];
  }
}
