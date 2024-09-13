import 'dart:async';
import 'package:dart_ping/dart_ping.dart';


class DNSService {
  Future<double> pingDNS(String ipAddress) async {
    final ping = Ping(ipAddress);
    await for (final PingData data in ping.stream) {
      if (data.response != null) {
        return data.response!.time!.inMilliseconds.toDouble();
      } 
    }
    return -1; // Return -1 if ping fails
  }
}