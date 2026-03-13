// Group Sync Member Model
class SyncMember {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final int batteryLevel; // 0-100
  final DateTime lastUpdate;
  final bool isConnected;
  final String? statusMessage; // Optional custom status

  SyncMember({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    required this.batteryLevel,
    required this.lastUpdate,
    required this.isConnected,
    this.statusMessage,
  });

  factory SyncMember.fromJson(Map<String, dynamic> json) {
    return SyncMember(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      batteryLevel: json['batteryLevel'] ?? 0,
      lastUpdate: DateTime.parse(
          json['lastUpdate'] ?? DateTime.now().toIso8601String()),
      isConnected: json['isConnected'] ?? false,
      statusMessage: json['statusMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'batteryLevel': batteryLevel,
      'lastUpdate': lastUpdate.toIso8601String(),
      'isConnected': isConnected,
      'statusMessage': statusMessage,
    };
  }

  String getBatteryIcon() {
    if (batteryLevel >= 80) return '🔋';
    if (batteryLevel >= 50) return '🔋';
    if (batteryLevel >= 20) return '🪫';
    return '🪫';
  }

  String getBatteryStatus() {
    if (batteryLevel >= 80) return 'Good';
    if (batteryLevel >= 50) return 'Medium';
    if (batteryLevel >= 20) return 'Low';
    return 'Critical';
  }

  bool needsAlert() {
    // Alert if battery < 15% or no update in 10 minutes
    final timeSinceUpdate = DateTime.now().difference(lastUpdate);
    return batteryLevel < 15 || timeSinceUpdate.inMinutes > 10;
  }
}
