import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  static String routeName = "/leaderboard";

  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _entries = [];
  User? _currentUser;
  bool _isLoading = true;
  int? _userRank;
  String _studentNumber = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Normalize entry to have both snake_case and camelCase keys
  void _normalizeEntry(Map<String, dynamic> entry) {
    if (entry.containsKey('totalPoints') && !entry.containsKey('total_points')) {
      entry['total_points'] = entry['totalPoints'];
    }
    if (entry.containsKey('total_points') && !entry.containsKey('totalPoints')) {
      entry['totalPoints'] = entry['total_points'];
    }
    if (entry.containsKey('ecoLevel') && !entry.containsKey('eco_level')) {
      entry['eco_level'] = entry['ecoLevel'];
    }
    if (entry.containsKey('eco_level') && !entry.containsKey('ecoLevel')) {
      entry['ecoLevel'] = entry['eco_level'];
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = await DatabaseManager.instance.getUser();
      final prefs = await SharedPreferences.getInstance();
      _studentNumber = prefs.getString('student_number') ?? '';

      // Try backend first
      _entries = await ApiService.instance.getLeaderboard();
      for (final e in _entries) _normalizeEntry(e);

      // If backend returned nothing, fall back to local leaderboard table
      if (_entries.isEmpty) {
        if (_currentUser != null) {
          await DatabaseManager.instance.updateRealUserInLeaderboard(_currentUser!);
        }
        _entries = await DatabaseManager.instance.getLeaderboard();
        for (final e in _entries) _normalizeEntry(e);
      }

      // Always overlay the current user's latest local data
      if (_currentUser != null && _studentNumber.isNotEmpty) {
        final existingIndex = _entries.indexWhere(
          (e) => e['student_number'] == _studentNumber,
        );
        final userEntry = {
          'rank': existingIndex >= 0 ? _entries[existingIndex]['rank'] : _entries.length + 1,
          'student_number': _studentNumber,
          'name': _currentUser!.name,
          'total_points': _currentUser!.totalPoints,
          'totalPoints': _currentUser!.totalPoints,
          'eco_level': _currentUser!.ecoLevel,
          'ecoLevel': _currentUser!.ecoLevel,
          'isRealUser': 1,
        };
        if (existingIndex >= 0) {
          _entries[existingIndex] = userEntry;
        } else {
          _entries.add(userEntry);
        }
        // Re-sort by total_points descending and reassign ranks
        _entries.sort((a, b) => (b['total_points'] as int).compareTo(a['total_points'] as int));
        for (int i = 0; i < _entries.length; i++) {
          _entries[i]['rank'] = i + 1;
        }
      }

      // Find current user's rank
      _userRank = null;
      if (_studentNumber.isNotEmpty) {
        for (final entry in _entries) {
          if (entry['student_number'] == _studentNumber) {
            _userRank = entry['rank'] as int?;
            break;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error loading leaderboard: $e");
      setState(() => _isLoading = false);
    }
  }

  Widget? _getTrophy(int rank) {
    if (rank == 1) return Icon(Icons.emoji_events, color: Colors.amber, size: getProportionateScreenWidth(18));
    if (rank == 2) return Icon(Icons.emoji_events, color: Colors.grey, size: getProportionateScreenWidth(18));
    if (rank == 3) return Icon(Icons.emoji_events, color: Colors.orange, size: getProportionateScreenWidth(18));
    return null;
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade100;
    if (rank == 2) return Colors.grey.shade200;
    if (rank == 3) return Colors.orange.shade100;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xfff5f5f5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // User Rank Card
                  if (_currentUser != null && _userRank != null)
                    Container(
                      margin: EdgeInsets.all(getProportionateScreenWidth(16)),
                      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.teal.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '#$_userRank',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(22),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: getProportionateScreenWidth(16)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOU',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(12),
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  _currentUser!.name,
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(20),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      User.getLevelIcon(_currentUser!.ecoLevel),
                                      color: Colors.white.withOpacity(0.9),
                                      size: getProportionateScreenWidth(14),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _currentUser!.ecoLevel,
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(14),
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_currentUser!.totalPoints}',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(24),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'pts',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(12),
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // Top 3 Podium
                  if (_entries.length >= 3)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 2nd place
                          _buildPodiumItem(_entries[1], 2, 80),
                          // 1st place
                          _buildPodiumItem(_entries[0], 1, 100),
                          // 3rd place
                          _buildPodiumItem(_entries[2], 3, 80),
                        ],
                      ),
                    ),

                  SizedBox(height: getProportionateScreenHeight(16)),

                  // List header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Rank',
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(14),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                        SizedBox(width: getProportionateScreenWidth(40)),
                        Expanded(
                          child: Text(
                            'Student',
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(14),
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        Text(
                          'Points',
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(14),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: getProportionateScreenHeight(8)),

                  // Leaderboard list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final rank = index + 1;
                        final isRealUser = entry['student_number'] == _studentNumber;
                        final bool isTop3 = rank <= 3;

                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(16),
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isRealUser
                                ? Colors.green.shade50
                                : (isTop3 ? _getRankColor(rank) : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: isRealUser
                                ? Border.all(color: Colors.green.shade200)
                                : null,
                          ),
                          child: ListTile(
                            leading: SizedBox(
                              width: 40,
                              child: Row(
                                children: [
                                  if (_getTrophy(rank) != null) ...[
                                    _getTrophy(rank)!,
                                    SizedBox(width: 2),
                                  ],
                                  Text(
                                    '#$rank',
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(14),
                                      fontWeight: FontWeight.bold,
                                      color: isTop3 ? Colors.black : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry['name'],
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(15),
                                      fontWeight: isRealUser ? FontWeight.bold : FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                if (isRealUser)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'YOU',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  User.getLevelIcon(entry['eco_level']),
                                  color: Colors.grey[600],
                                  size: getProportionateScreenWidth(13),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  entry['eco_level'],
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(13),
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '${entry['total_points']}',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(16),
                                fontWeight: FontWeight.bold,
                                color: isTop3 ? Colors.black : Colors.grey[700],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> entry, int rank, double height) {
    final List<Color> colors = [
      Colors.amber,
      Colors.grey.shade400,
      Colors.orange.shade300,
    ];
    final trophyIcons = [
      Icon(Icons.emoji_events, color: Colors.amber, size: getProportionateScreenWidth(28)),
      Icon(Icons.emoji_events, color: Colors.grey, size: getProportionateScreenWidth(28)),
      Icon(Icons.emoji_events, color: Colors.orange, size: getProportionateScreenWidth(28)),
    ];

    return Expanded(
      child: Column(
        children: [
          trophyIcons[rank - 1],
          SizedBox(height: getProportionateScreenHeight(4)),
          CircleAvatar(
            radius: rank == 1 ? 30 : 24,
            backgroundColor: colors[rank - 1],
            child: Text(
              entry['name'].toString().substring(0, 1),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: getProportionateScreenWidth(rank == 1 ? 22 : 18)),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Text(
            entry['name'],
            style: TextStyle(
              fontSize: getProportionateScreenWidth(12),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${entry['total_points']} pts',
            style: TextStyle(
              fontSize: getProportionateScreenWidth(11),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(4)),
          Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors[rank - 1].withOpacity(0.8),
                  colors[rank - 1].withOpacity(0.4),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
