// dns_model.dart
class DNSModel {
  final String name;
  final List<String> ipAddress;
  final bool isCustom;

  DNSModel({
    required this.name,
    required this.ipAddress,
    this.isCustom = false,
  });

  // Convert DNSModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ipAddress': ipAddress,
      'isCustom': isCustom,
    };
  }

  // Create DNSModel from a Map
  factory DNSModel.fromMap(Map<String, dynamic> map) {
    return DNSModel(
      name: map['name'],
      ipAddress: List<String>.from(map['ipAddress']),
      isCustom: map['isCustom'] ?? false,
    );
  }
}
