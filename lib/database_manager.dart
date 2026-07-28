import 'dart:io';
import 'package:deep_waste/models/Category.dart';
import 'package:deep_waste/models/Item.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/models/disposal_record.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManager {
  static const _dbName = "deepwaste.db";

  DatabaseManager._privateConstructor();
  static final DatabaseManager instance =
      DatabaseManager._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _dbName);

    var dbExists = await databaseExists(path);

    if (!dbExists) {
      print("db not exist");
      print("Creating new copy from asset");

      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load(join("assets", _dbName));
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await File(path).writeAsBytes(bytes, flush: true);

      // The bundled DB has user_version 0, which makes sqflite skip onUpgrade.
      // Force it to 1 so the full migration chain (1 -> 3) runs.
      Database tempDb = await openDatabase(path);
      await tempDb.setVersion(1);
      await tempDb.close();
    } else {
      print("Opening existing database");
    }

    Database db = await openDatabase(
      path,
      version: 3,
      onUpgrade: _onUpgrade,
    );

    // Safety repair: ensure the profileImage column exists even if user_version
    // was bumped without this column being present (e.g. existing AVD installs).
    await _ensureUserTableSchema(db);

    return db;
  }

  Future<void> _ensureUserTableSchema(Database db) async {
    try {
      final columns = await db.rawQuery("PRAGMA table_info(User)");
      bool hasProfileImage = columns.any((c) => c['name'] == 'profileImage');
      if (!hasProfileImage) {
        print("Repairing User table: adding missing profileImage column");
        await db.execute('ALTER TABLE User ADD COLUMN profileImage TEXT');
      }
      bool hasTotalPoints = columns.any((c) => c['name'] == 'totalPoints');
      if (!hasTotalPoints) {
        print("Repairing User table: adding missing totalPoints column");
        await db.execute('ALTER TABLE User ADD COLUMN totalPoints INTEGER DEFAULT 0');
      }
      bool hasEcoLevel = columns.any((c) => c['name'] == 'ecoLevel');
      if (!hasEcoLevel) {
        print("Repairing User table: adding missing ecoLevel column");
        await db.execute('ALTER TABLE User ADD COLUMN ecoLevel TEXT DEFAULT "Seedling"');
      }
      bool hasCurrentStreak = columns.any((c) => c['name'] == 'currentStreak');
      if (!hasCurrentStreak) {
        print("Repairing User table: adding missing currentStreak column");
        await db.execute('ALTER TABLE User ADD COLUMN currentStreak INTEGER DEFAULT 0');
      }
      bool hasMaxStreak = columns.any((c) => c['name'] == 'maxStreak');
      if (!hasMaxStreak) {
        print("Repairing User table: adding missing maxStreak column");
        await db.execute('ALTER TABLE User ADD COLUMN maxStreak INTEGER DEFAULT 0');
      }
      bool hasLastDisposalDate = columns.any((c) => c['name'] == 'lastDisposalDate');
      if (!hasLastDisposalDate) {
        print("Repairing User table: adding missing lastDisposalDate column");
        await db.execute('ALTER TABLE User ADD COLUMN lastDisposalDate TEXT');
      }
      bool hasOnboardingComplete = columns.any((c) => c['name'] == 'onboardingComplete');
      if (!hasOnboardingComplete) {
        print("Repairing User table: adding missing onboardingComplete column");
        await db.execute('ALTER TABLE User ADD COLUMN onboardingComplete INTEGER DEFAULT 0');
      }
    } catch (e) {
      print("Schema repair warning: $e");
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from $oldVersion to $newVersion");

    if (oldVersion < 2) {
      // Add new columns to User table if they don't exist
      try {
        await db.execute('ALTER TABLE User ADD COLUMN totalPoints INTEGER DEFAULT 0');
      } catch (e) {
        print("Column totalPoints may already exist: $e");
      }
      try {
        await db.execute('ALTER TABLE User ADD COLUMN ecoLevel TEXT DEFAULT "Seedling"');
      } catch (e) {
        print("Column ecoLevel may already exist: $e");
      }
      try {
        await db.execute('ALTER TABLE User ADD COLUMN currentStreak INTEGER DEFAULT 0');
      } catch (e) {
        print("Column currentStreak may already exist: $e");
      }
      try {
        await db.execute('ALTER TABLE User ADD COLUMN maxStreak INTEGER DEFAULT 0');
      } catch (e) {
        print("Column maxStreak may already exist: $e");
      }
      try {
        await db.execute('ALTER TABLE User ADD COLUMN lastDisposalDate TEXT');
      } catch (e) {
        print("Column lastDisposalDate may already exist: $e");
      }
      try {
        await db.execute('ALTER TABLE User ADD COLUMN onboardingComplete INTEGER DEFAULT 0');
      } catch (e) {
        print("Column onboardingComplete may already exist: $e");
      }

      // Create DisposalRecord table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS DisposalRecord (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          pointsAwarded INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          qrCode TEXT,
          binName TEXT,
          imagePath TEXT
        )
      ''');

      // Create LeaderboardEntry table for seeded demo data
      await db.execute('''
        CREATE TABLE IF NOT EXISTS LeaderboardEntry (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          ecoLevel TEXT NOT NULL,
          totalPoints INTEGER NOT NULL,
          isRealUser INTEGER DEFAULT 0
        )
      ''');

      // Seed demo leaderboard data
      await _seedLeaderboardData(db);
    }

    if (oldVersion < 3) {
      // Fix: Add the missing profileImage column
      try {
        await db.execute('ALTER TABLE User ADD COLUMN profileImage TEXT');
      } catch (e) {
        print("Column profileImage may already exist: $e");
      }
    }
  }

  Future<void> _seedLeaderboardData(Database db) async {
    final demoEntries = [
      {'id': 'demo1', 'name': 'Alice M.', 'ecoLevel': 'Eco Giant', 'totalPoints': 15200, 'isRealUser': 0},
      {'id': 'demo2', 'name': 'Bob K.', 'ecoLevel': 'Protector', 'totalPoints': 8700, 'isRealUser': 0},
      {'id': 'demo3', 'name': 'Sarah N.', 'ecoLevel': 'Protector', 'totalPoints': 7200, 'isRealUser': 0},
      {'id': 'demo4', 'name': 'John P.', 'ecoLevel': 'Guardian', 'totalPoints': 4800, 'isRealUser': 0},
      {'id': 'demo5', 'name': 'Maria T.', 'ecoLevel': 'Guardian', 'totalPoints': 3900, 'isRealUser': 0},
      {'id': 'demo6', 'name': 'David R.', 'ecoLevel': 'Sprout', 'totalPoints': 1200, 'isRealUser': 0},
      {'id': 'demo7', 'name': 'James L.', 'ecoLevel': 'Sprout', 'totalPoints': 850, 'isRealUser': 0},
      {'id': 'demo8', 'name': 'Grace W.', 'ecoLevel': 'Sprout', 'totalPoints': 620, 'isRealUser': 0},
      {'id': 'demo9', 'name': 'Peter M.', 'ecoLevel': 'Seedling', 'totalPoints': 350, 'isRealUser': 0},
      {'id': 'demo10', 'name': 'Linda C.', 'ecoLevel': 'Seedling', 'totalPoints': 180, 'isRealUser': 0},
    ];

    for (var entry in demoEntries) {
      try {
        await db.insert('LeaderboardEntry', entry, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (e) {
        print("Error seeding leaderboard entry: $e");
      }
    }
    print("Seeded ${demoEntries.length} demo leaderboard entries");
  }

  Future<void> initializeTables() async {
    final db = await instance.database;
    await _onUpgrade(db, 1, 3);
  }

  // ---- Category ----
  Future<List<Category>> getCategories() async {
    final db = await instance.database;
    final categories = await db.query('Category');

    return categories.isNotEmpty
        ? categories.map((c) => Category.fromMap(c)).toList()
        : <Category>[];
  }

  // ---- Item ----
  Future<List<Item>> getItems() async {
    final db = await instance.database;
    final items = await db.query('Item');

    return items.isNotEmpty
        ? items.map((c) => Item.fromMap(c)).toList()
        : <Item>[];
  }

  Future<int> updateItem(Item item) async {
    final db = await instance.database;
    return await db.update(
      "Item",
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // ---- User ----
  Future<User?> getUser() async {
    final db = await instance.database;
    final user = await db.query('User');

    if (user.isEmpty) return null;
    return User.fromMap(user.first);
  }

  Future<int> insertUser(User profile) async {
    final db = await instance.database;
    return await db.insert("User", profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUser(User profile) async {
    final db = await instance.database;
    return await db.update(
      "User",
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<int> deleteUser(int userId) async {
    final db = await instance.database;
    return await db.delete(
      "User",
      where: "id = ?",
      whereArgs: [userId],
    );
  }

  // ---- DisposalRecord ----
  Future<int> insertDisposal(DisposalRecord record) async {
    final db = await instance.database;
    return await db.insert("DisposalRecord", record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DisposalRecord>> getDisposals({int limit = 50}) async {
    final db = await instance.database;
    final records = await db.query(
      'DisposalRecord',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return records.isNotEmpty
        ? records.map((r) => DisposalRecord.fromMap(r)).toList()
        : <DisposalRecord>[];
  }

  Future<List<DisposalRecord>> getDisposalsByCategory(String category) async {
    final db = await instance.database;
    final records = await db.query(
      'DisposalRecord',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'timestamp DESC',
    );

    return records.isNotEmpty
        ? records.map((r) => DisposalRecord.fromMap(r)).toList()
        : <DisposalRecord>[];
  }

  Future<int> getTotalDisposals() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM DisposalRecord');
    return (result.first['count'] as int?) ?? 0;
  }

  // ---- Leaderboard ----
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final db = await instance.database;

    // Get all leaderboard entries (demo + real user merged)
    final entries = await db.query(
      'LeaderboardEntry',
      orderBy: 'totalPoints DESC',
    );

    return entries;
  }

  Future<void> updateRealUserInLeaderboard(User user) async {
    final db = await instance.database;
    await db.insert(
      'LeaderboardEntry',
      {
        'id': 'real_user',
        'name': user.name,
        'ecoLevel': user.ecoLevel,
        'totalPoints': user.totalPoints,
        'isRealUser': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> resetLeaderboardDemoData() async {
    final db = await instance.database;
    await db.delete('LeaderboardEntry', where: 'isRealUser = ?', whereArgs: [0]);
    await _seedLeaderboardData(db);
  }

  // ---- Gamification Stats ----
  Future<int> getTodayPoints() async {
    final db = await instance.database;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final result = await db.rawQuery(
      "SELECT SUM(pointsAwarded) as total FROM DisposalRecord WHERE timestamp LIKE ?",
      ['$todayStr%'],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<Map<String, int>> getCategoryBreakdown() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM DisposalRecord GROUP BY category',
    );
    
    Map<String, int> breakdown = {};
    for (var row in result) {
      breakdown[row['category'] as String] = (row['count'] as int?) ?? 0;
    }
    return breakdown;
  }
}
