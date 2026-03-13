class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final bool receivesSms;
  final bool receivesEmail;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.receivesSms = true,
    this.receivesEmail = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      email: json['email'],
      receivesSms: json['receivesSms'] ?? true,
      receivesEmail: json['receivesEmail'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'receivesSms': receivesSms,
        'receivesEmail': receivesEmail,
      };
}
