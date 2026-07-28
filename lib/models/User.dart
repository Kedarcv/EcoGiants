import 'package:flutter/material.dart';

class User {
  final int id;
  final String name;
  final String? profileImage;
  final int totalPoints;
  final String ecoLevel;
  final int currentStreak;
  final int maxStreak;
  final String? lastDisposalDate;
  final bool onboardingComplete;

  // Eco levels thresholds
  static const Map<String, int> levelThresholds = {
    'Seedling': 0,
    'Sprout': 500,
    'Guardian': 1500,
    'Protector': 5000,
    'Eco Giant': 10000,
  };

  // Points per category
  static const Map<String, int> pointsByCategory = {
    'Hazardous': 50,
    'E-Waste': 40,
    'Recyclable': 30,
    'Organic': 20,
    'General': 10,
    // Legacy mapping for old categories
    'Trash': 10,
    'Plastic': 30,
    'Paper': 30,
    'Glass': 30,
    'Metal': 30,
    'Cardboard': 30,
  };

  User({
    required this.id,
    required this.name,
    this.profileImage,
    this.totalPoints = 0,
    this.ecoLevel = 'Seedling',
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.lastDisposalDate,
    this.onboardingComplete = false,
  });

  factory User.fromMap(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      profileImage: json['profileImage'],
      totalPoints: json['totalPoints'] ?? 0,
      ecoLevel: json['ecoLevel'] ?? 'Seedling',
      currentStreak: json['currentStreak'] ?? 0,
      maxStreak: json['maxStreak'] ?? 0,
      lastDisposalDate: json['lastDisposalDate'],
      onboardingComplete: json['onboardingComplete'] == 1 || json['onboardingComplete'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "profileImage": profileImage,
      "totalPoints": totalPoints,
      "ecoLevel": ecoLevel,
      "currentStreak": currentStreak,
      "maxStreak": maxStreak,
      "lastDisposalDate": lastDisposalDate,
      "onboardingComplete": onboardingComplete ? 1 : 0,
    };
  }

  /// Calculate eco level from total points
  static String calculateLevel(int points) {
    if (points >= 10000) return 'Eco Giant';
    if (points >= 5000) return 'Protector';
    if (points >= 1500) return 'Guardian';
    if (points >= 500) return 'Sprout';
    return 'Seedling';
  }

  /// Get minimum points needed to reach a level
  static int getLevelMinPoints(String level) {
    return levelThresholds[level] ?? 0;
  }

  /// Get max points for current level (to show progress bar)
  static int getLevelMaxPoints(String level) {
    switch (level) {
      case 'Seedling':
        return 499;
      case 'Sprout':
        return 1499;
      case 'Guardian':
        return 4999;
      case 'Protector':
        return 9999;
      case 'Eco Giant':
        return 99999;
      default:
        return 499;
    }
  }

  /// Get points for next level
  static int pointsToNextLevel(int points) {
    String currentLevel = calculateLevel(points);
    int minForNext = 0;
    switch (currentLevel) {
      case 'Seedling':
        minForNext = 500;
        break;
      case 'Sprout':
        minForNext = 1500;
        break;
      case 'Guardian':
        minForNext = 5000;
        break;
      case 'Protector':
        minForNext = 10000;
        break;
      case 'Eco Giant':
        return 0;
    }
    return minForNext - points;
  }

  /// Get level icon as Phosphor IconData
  static IconData getLevelIcon(String level) {
    switch (level) {
      case 'Seedling':
        return Icons.eco;
      case 'Sprout':
        return Icons.park;
      case 'Guardian':
        return Icons.shield;
      case 'Protector':
        return Icons.verified_user;
      case 'Eco Giant':
        return Icons.public;
      default:
        return Icons.eco;
    }
  }

  /// Get points needed for current level progress bar [0.0 - 1.0]
  static double getLevelProgress(int points) {
    String level = calculateLevel(points);
    int minPoints = getLevelMinPoints(level);
    int maxPoints = getLevelMaxPoints(level);
    if (points >= maxPoints) return 1.0;
    return (points - minPoints) / (maxPoints - minPoints);
  }

  User copyWith({
    int? id,
    String? name,
    String? profileImage,
    int? totalPoints,
    String? ecoLevel,
    int? currentStreak,
    int? maxStreak,
    String? lastDisposalDate,
    bool? onboardingComplete,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      totalPoints: totalPoints ?? this.totalPoints,
      ecoLevel: ecoLevel ?? this.ecoLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      lastDisposalDate: lastDisposalDate ?? this.lastDisposalDate,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
