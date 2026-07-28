class DisposalRecord {
  final String id;
  final String category;
  final int pointsAwarded;
  final String timestamp;
  final String? qrCode;
  final String? binName;
  final String? imagePath;

  DisposalRecord({
    required this.id,
    required this.category,
    required this.pointsAwarded,
    required this.timestamp,
    this.qrCode,
    this.binName,
    this.imagePath,
  });

  factory DisposalRecord.fromMap(Map<String, dynamic> json) {
    return DisposalRecord(
      id: json['id'].toString(),
      category: json['category'],
      pointsAwarded: json['pointsAwarded'],
      timestamp: json['timestamp'],
      qrCode: json['qrCode'],
      binName: json['binName'],
      imagePath: json['imagePath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "category": category,
      "pointsAwarded": pointsAwarded,
      "timestamp": timestamp,
      "qrCode": qrCode,
      "binName": binName,
      "imagePath": imagePath,
    };
  }
}
