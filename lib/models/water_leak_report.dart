class WaterLeakReport {
  final int? id;
  final String imagePath;
  final double latitude;
  final double longitude;
  final String locationName;
  final String severity;
  final String aiReport;
  final String status;
  final String timestamp;

  WaterLeakReport({
    this.id,
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.severity,
    required this.aiReport,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'severity': severity,
      'aiReport': aiReport,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory WaterLeakReport.fromMap(Map<String, dynamic> map) {
    return WaterLeakReport(
      id: map['id'] as int?,
      imagePath: map['imagePath'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? -17.8252,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 31.0335,
      locationName: map['locationName'] as String? ?? 'ZOU Campus Node',
      severity: map['severity'] as String? ?? 'Medium Drip',
      aiReport: map['aiReport'] as String? ?? 'Active water leak detected.',
      status: map['status'] as String? ?? 'Pending',
      timestamp: map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
