# Eco-Giants ZOU — Domain Models & Entities

## Core Domain Events

All state changes are captured as immutable events for auditing and analytics.

```dart
abstract class DomainEvent {
  final String eventId;
  final DateTime timestamp;
  final String aggregateId;
  final String? studentId;

  DomainEvent({
    required this.eventId,
    required this.timestamp,
    required this.aggregateId,
    this.studentId,
  });
}
```

### Auth Events
```dart
class StudentRegistered extends DomainEvent {
  final String email;
  final String studentId;
  final String displayName;

  StudentRegistered({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.email,
    required this.studentId,
    required this.displayName,
  });
}

class StudentLoggedIn extends DomainEvent {
  final String deviceInfo;

  StudentLoggedIn({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.deviceInfo,
  });
}

class StudentProfileUpdated extends DomainEvent {
  final String field;
  final dynamic oldValue;
  final dynamic newValue;

  StudentProfileUpdated({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.field,
    required this.oldValue,
    required this.newValue,
  });
}
```

### Waste Events
```dart
class ItemClassified extends DomainEvent {
  final WasteCategory category;
  final double confidence;
  final String imageUrl;
  final bool wasManual;

  ItemClassified({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.category,
    required this.confidence,
    required this.imageUrl,
    this.wasManual = false,
  });
}

class DisposalVerified extends DomainEvent {
  final String classificationId;
  final String binId;
  final String qrCode;
  final int pointsAwarded;
  final GeoLocation location;

  DisposalVerified({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.classificationId,
    required this.binId,
    required this.qrCode,
    required this.pointsAwarded,
    required this.location,
  });
}

class BinLocationUpdated extends DomainEvent {
  final String binId;
  final GeoLocation newLocation;
  final Set<WasteCategory> acceptedCategories;

  BinLocationUpdated({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required this.binId,
    required this.newLocation,
    required this.acceptedCategories,
  });
}
```

### Gamification Events
```dart
class PointsAwarded extends DomainEvent {
  final int points;
  final String reason;
  final WasteCategory category;
  final int streakMultiplier;

  PointsAwarded({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.points,
    required this.reason,
    required this.category,
    this.streakMultiplier = 1,
  });
}

class EcoLevelUnlocked extends DomainEvent {
  final EcoLevel oldLevel;
  final EcoLevel newLevel;
  final int totalPoints;

  EcoLevelUnlocked({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.oldLevel,
    required this.newLevel,
    required this.totalPoints,
  });
}

class RewardRedeemed extends DomainEvent {
  final String rewardId;
  final String rewardName;
  final String redemptionCode;

  RewardRedeemed({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.rewardId,
    required this.rewardName,
    required this.redemptionCode,
  });
}

class LeaderboardUpdated extends DomainEvent {
  final int newRank;
  final int oldRank;

  LeaderboardUpdated({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.newRank,
    required this.oldRank,
  });
}

class StreakUpdated extends DomainEvent {
  final int newStreak;
  final int oldStreak;
  final bool wasBroken;

  StreakUpdated({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.newStreak,
    required this.oldStreak,
    this.wasBroken = false,
  });
}
```

### Copilot Events
```dart
class ConversationStarted extends DomainEvent {
  final String conversationId;

  ConversationStarted({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.conversationId,
  });
}

class MessageExchanged extends DomainEvent {
  final String conversationId;
  final String messageId;
  final String role;
  final String content;

  MessageExchanged({
    required super.eventId,
    required super.timestamp,
    required super.aggregateId,
    required super.studentId,
    required this.conversationId,
    required this.messageId,
    required this.role,
    required this.content,
  });
}
```

---

## Domain Entities

### Student (Identity Aggregate)

```dart
class Student {
  final StudentId id;
  final Email email;
  final String displayName;
  final String? studentNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  Student({
    required this.id,
    required this.email,
    required this.displayName,
    this.studentNumber,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  Student updateDisplayName(String newName) => Student(
    id: id,
    email: email,
    displayName: newName,
    studentNumber: studentNumber,
    profileImageUrl: profileImageUrl,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt,
  );

  Student updateProfileImage(String? url) => Student(
    id: id,
    email: email,
    displayName: displayName,
    studentNumber: studentNumber,
    profileImageUrl: url,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt,
  );

  Student recordLogin() => Student(
    id: id,
    email: email,
    displayName: displayName,
    studentNumber: studentNumber,
    profileImageUrl: profileImageUrl,
    createdAt: createdAt,
    lastLoginAt: DateTime.now(),
  );
}
```

### WasteItem (Waste Aggregate)

```dart
class WasteItem {
  final String id;
  final StudentId studentId;
  final WasteCategory category;
  final double confidence;
  final String imageUrl;
  final DateTime classifiedAt;
  final bool wasManualSelection;
  final DisposalVerification? verification;

  WasteItem({
    required this.id,
    required this.studentId,
    required this.category,
    required this.confidence,
    required this.imageUrl,
    required this.classifiedAt,
    this.wasManualSelection = false,
    this.verification,
  });

  bool get isVerified => verification != null && verification!.verified;
  bool get isPending => verification == null;

  WasteItem verify(DisposalVerification verification) => WasteItem(
    id: id,
    studentId: studentId,
    category: category,
    confidence: confidence,
    imageUrl: imageUrl,
    classifiedAt: classifiedAt,
    wasManualSelection: wasManualSelection,
    verification: verification,
  );
}

class DisposalVerification {
  final bool verified;
  final String binId;
  final String qrCode;
  final int pointsAwarded;
  final DateTime verifiedAt;
  final GeoLocation? location;

  DisposalVerification({
    required this.verified,
    required this.binId,
    required this.qrCode,
    required this.pointsAwarded,
    required this.verifiedAt,
    this.location,
  });
}
```

### WasteCategory (Value Object)

```dart
enum WasteCategory {
  recyclable,
  organic,
  eWaste,
  general,
  hazardous;

  String get displayName => switch (this) {
    WasteCategory.recyclable => 'Recyclable',
    WasteCategory.organic => 'Organic',
    WasteCategory.eWaste => 'E-Waste',
    WasteCategory.general => 'General',
    WasteCategory.hazardous => 'Hazardous',
  };

  String get icon => switch (this) {
    WasteCategory.recyclable => '♻️',
    WasteCategory.organic => '🍂',
    WasteCategory.eWaste => '🔌',
    WasteCategory.general => '🗑️',
    WasteCategory.hazardous => '⚠️',
  };

  Color get color => switch (this) {
    WasteCategory.recyclable => AppColors.recyclable,
    WasteCategory.organic => AppColors.organic,
    WasteCategory.eWaste => AppColors.eWaste,
    WasteCategory.general => AppColors.general,
    WasteCategory.hazardous => AppColors.hazardous,
  };

  int get basePoints => switch (this) {
    WasteCategory.recyclable => 30,
    WasteCategory.organic => 20,
    WasteCategory.eWaste => 40,
    WasteCategory.general => 10,
    WasteCategory.hazardous => 50,
  };

  String get description => switch (this) {
    WasteCategory.recyclable => 'Items that can be processed into new materials like paper, plastic, glass, and metal.',
    WasteCategory.organic => 'Biodegradable materials like food scraps, yard waste, and compostable items.',
    WasteCategory.eWaste => 'Electronic devices, batteries, and electrical equipment that require special recycling.',
    WasteCategory.general => 'Non-recyclable, non-hazardous waste that goes to landfill.',
    WasteCategory.hazardous => 'Dangerous materials like chemicals, sharps, and toxic substances requiring special handling.',
  };

  static WasteCategory? fromString(String value) {
    return WasteCategory.values.cast<WasteCategory?>().firstWhere(
      (e) => e?.name.toLowerCase() == value.toLowerCase(),
      orElse: () => null,
    );
  }
}
```

### BinLocation (Value Object / Entity)

```dart
class BinLocation {
  final String id;
  final String name;
  final String description;
  final GeoLocation location;
  final Set<WasteCategory> acceptedCategories;
  final String qrCode;
  final bool isActive;

  BinLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.acceptedCategories,
    required this.qrCode,
    this.isActive = true,
  });

  bool acceptsCategory(WasteCategory category) => 
    acceptedCategories.contains(category);

  double distanceFrom(GeoLocation other) => 
    location.distanceTo(other);
}

class GeoLocation {
  final double latitude;
  final double longitude;

  GeoLocation({
    required this.latitude,
    required this.longitude,
  });

  double distanceTo(GeoLocation other) {
    // Haversine formula implementation
    const earthRadiusKm = 6371;
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c * 1000; // Return meters
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
```

### Score (Gamification Aggregate)

```dart
class Score {
  final StudentId studentId;
  final Points totalPoints;
  final EcoLevel currentLevel;
  final int currentStreak;
  final int maxStreak;
  final DateTime? lastDisposalDate;
  final int totalDisposals;
  final Map<WasteCategory, int> disposalsByCategory;

  Score({
    required this.studentId,
    required this.totalPoints,
    required this.currentLevel,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.lastDisposalDate,
    this.totalDisposals = 0,
    this.disposalsByCategory = const {},
  });

  factory Score.initial(StudentId studentId) => Score(
    studentId: studentId,
    totalPoints: Points.zero(),
    currentLevel: EcoLevel.seedling,
  );

  Score addPoints(int points, WasteCategory category) {
    final newPoints = totalPoints.add(points);
    final newLevel = EcoLevel.fromPoints(newPoints.value);
    final newDisposals = totalDisposals + 1;
    final newCategoryCounts = Map<WasteCategory, int>.from(disposalsByCategory);
    newCategoryCounts[category] = (newCategoryCounts[category] ?? 0) + 1;

    return Score(
      studentId: studentId,
      totalPoints: newPoints,
      currentLevel: newLevel,
      currentStreak: currentStreak,
      maxStreak: maxStreak,
      lastDisposalDate: DateTime.now(),
      totalDisposals: newDisposals,
      disposalsByCategory: newCategoryCounts,
    );
  }

  Score updateStreak() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    int newStreak;
    bool wasBroken = false;

    if (lastDisposalDate == null) {
      newStreak = 1;
    } else {
      final lastDate = DateTime(lastDisposalDate!.year, lastDisposalDate!.month, lastDisposalDate!.day);
      final todayDate = DateTime(today.year, today.month, today.day);
      final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);

      if (lastDate == yesterdayDate) {
        newStreak = currentStreak + 1;
      } else if (lastDate == todayDate) {
        newStreak = currentStreak; // Already counted today
      } else {
        newStreak = 1;
        wasBroken = true;
      }
    }

    return Score(
      studentId: studentId,
      totalPoints: totalPoints,
      currentLevel: currentLevel,
      currentStreak: newStreak,
      maxStreak: math.max(maxStreak, newStreak),
      lastDisposalDate: DateTime.now(),
      totalDisposals: totalDisposals,
      disposalsByCategory: disposalsByCategory,
    );
  }

  double get progressToNextLevel {
    if (currentLevel.isMaxLevel) return 1.0;
    final range = currentLevel.maxPoints - currentLevel.minPoints;
    final progress = totalPoints.value - currentLevel.minPoints;
    return (progress / range).clamp(0.0, 1.0);
  }

  int get pointsToNextLevel => 
    currentLevel.isMaxLevel ? 0 : currentLevel.maxPoints + 1 - totalPoints.value;
}
```

### EcoLevel (Value Object)

```dart
class EcoLevel {
  final String name;
  final int level;
  final int minPoints;
  final int maxPoints;
  final String icon;
  final String description;

  const EcoLevel({
    required this.name,
    required this.level,
    required this.minPoints,
    required this.maxPoints,
    required this.icon,
    required this.description,
  });

  bool get isMaxLevel => level == 5;

  static const seedling = EcoLevel(
    name: 'Seedling',
    level: 1,
    minPoints: 0,
    maxPoints: 499,
    icon: '🌱',
    description: 'Just getting started on your eco journey.',
  );

  static const sprout = EcoLevel(
    name: 'Sprout',
    level: 2,
    minPoints: 500,
    maxPoints: 1499,
    icon: '🌿',
    description: 'Growing stronger in your recycling habits.',
  );

  static const guardian = EcoLevel(
    name: 'Guardian',
    level: 3,
    minPoints: 1500,
    maxPoints: 4999,
    icon: '🌳',
    description: 'A true protector of the environment.',
  );

  static const protector = EcoLevel(
    name: 'Protector',
    level: 4,
    minPoints: 5000,
    maxPoints: 9999,
    icon: '🛡️',
    description: 'Leading the charge for a greener campus.',
  );

  static const ecoGiant = EcoLevel(
    name: 'Eco Giant',
    level: 5,
    minPoints: 10000,
    maxPoints: double.maxFinite.toInt(),
    icon: '🌍',
    description: 'A legendary force for environmental change.',
  );

  static const List<EcoLevel> all = [seedling, sprout, guardian, protector, ecoGiant];

  static EcoLevel fromPoints(int points) {
    return all.lastWhere((level) => points >= level.minPoints, orElse: () => seedling);
  }

  EcoLevel? get nextLevel {
    final index = all.indexOf(this);
    if (index < all.length - 1) return all[index + 1];
    return null;
  }
}
```

### Points (Value Object)

```dart
class Points {
  final int value;

  Points._(this.value);

  factory Points.zero() => Points._(0);
  factory Points.of(int value) => Points._(value.clamp(0, double.maxFinite.toInt()));

  Points add(int amount) => Points._(value + amount);
  Points subtract(int amount) => Points._((value - amount).clamp(0, double.maxFinite.toInt()));

  static int calculateWithStreak(int basePoints, int streak) {
    final multiplier = switch (streak) {
      < 3 => 1.0,
      < 7 => 1.2,
      < 14 => 1.5,
      < 30 => 2.0,
      _ => 2.5,
    };
    return (basePoints * multiplier).round();
  }

  @override
  bool operator ==(Object other) => other is Points && other.value == value;
  @override
  int get hashCode => value.hashCode;
}
```

### Reward (Entity)

```dart
class Reward {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final EcoLevel requiredLevel;
  final int stockRemaining;
  final bool isActive;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.requiredLevel,
    this.stockRemaining = -1, // -1 means unlimited
    this.isActive = true,
  });

  bool isEligible(EcoLevel studentLevel) => 
    isActive && studentLevel.level >= requiredLevel.level;
}

class Redemption {
  final String id;
  final String studentId;
  final String rewardId;
  final String rewardName;
  final String redemptionCode;
  final DateTime redeemedAt;
  final DateTime expiresAt;
  final RedemptionStatus status;

  Redemption({
    required this.id,
    required this.studentId,
    required this.rewardId,
    required this.rewardName,
    required this.redemptionCode,
    required this.redeemedAt,
    required this.expiresAt,
    this.status = RedemptionStatus.active,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsable => status == RedemptionStatus.active && !isExpired;
}

enum RedemptionStatus { active, used, expired, cancelled }
```

### LeaderboardEntry (Value Object)

```dart
class LeaderboardEntry {
  final int rank;
  final String studentId;
  final String displayName;
  final EcoLevel ecoLevel;
  final int totalPoints;
  final int disposalCount;

  LeaderboardEntry({
    required this.rank,
    required this.studentId,
    required this.displayName,
    required this.ecoLevel,
    required this.totalPoints,
    required this.disposalCount,
  });
}
```

### Conversation (Copilot Aggregate)

```dart
class Conversation {
  final String id;
  final StudentId studentId;
  final List<Message> messages;
  final DateTime startedAt;
  final DateTime? lastMessageAt;

  Conversation({
    required this.id,
    required this.studentId,
    required this.messages,
    required this.startedAt,
    this.lastMessageAt,
  });

  Conversation addMessage(Message message) => Conversation(
    id: id,
    studentId: studentId,
    messages: [...messages, message],
    startedAt: startedAt,
    lastMessageAt: message.timestamp,
  );

  String get contextForLLM {
    // Format conversation history for LLM context
    return messages.map((m) => '${m.role}: ${m.content}').join('\n');
  }
}

class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final List<MessageSource>? sources;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.sources,
  });
}

enum MessageRole { user, assistant }

class MessageSource {
  final String type;
  final String data;

  MessageSource({required this.type, required this.data});
}
```

### Value Objects

```dart
class StudentId {
  final String value;

  StudentId._(this.value);

  factory StudentId(String value) {
    if (value.isEmpty) throw ArgumentError('Student ID cannot be empty');
    return StudentId._(value);
  }

  @override
  bool operator ==(Object other) => other is StudentId && other.value == value;
  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class Email {
  final String value;

  Email._(this.value);

  factory Email(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@zou\.ac\.zw$');
    if (!emailRegex.hasMatch(value)) {
      throw ArgumentError('Invalid ZOU email format: $value');
    }
    return Email._(value);
  }

  @override
  bool operator ==(Object other) => other is Email && other.value == value;
  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class QrCode {
  final String value;
  final DateTime? expiresAt;

  QrCode._(this.value, [this.expiresAt]);

  factory QrCode(String value, {DateTime? expiresAt}) {
    if (value.isEmpty) throw ArgumentError('QR code cannot be empty');
    return QrCode._(value, expiresAt);
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValid => !isExpired;

  @override
  bool operator ==(Object other) => other is QrCode && other.value == value;
  @override
  int get hashCode => value.hashCode;
}
```

---

*Document Version: 1.0*
*Last Updated: 27 July 2026*
