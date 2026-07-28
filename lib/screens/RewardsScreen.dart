import 'dart:math';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:flutter/material.dart';

class LevelReward {
  final String name;
  final String description;
  final String requiredLevel;
  final IconData icon;
  final Color color;

  LevelReward({
    required this.name,
    required this.description,
    required this.requiredLevel,
    required this.icon,
    required this.color,
  });
}

class RewardsScreen extends StatefulWidget {
  static String routeName = "/rewards_screen";

  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  User? _user;
  bool _isLoading = true;

  final List<LevelReward> _rewards = [
    LevelReward(
      name: 'Eco Starter Badge',
      description: 'Welcome to the Eco-Giants movement!',
      requiredLevel: 'Seedling',
      icon: Icons.verified,
      color: Colors.green,
    ),
    LevelReward(
      name: 'Organic Cotton T-Shirt',
      description: 'ZOU branded eco-friendly t-shirt',
      requiredLevel: 'Sprout',
      icon: Icons.checkroom,
      color: Colors.teal,
    ),
    LevelReward(
      name: 'Steel Water Bottle',
      description: 'Reusable 500ml stainless steel bottle',
      requiredLevel: 'Guardian',
      icon: Icons.water_drop,
      color: Colors.blue,
    ),
    LevelReward(
      name: 'Eco Pen Set',
      description: 'Recycled material pen set',
      requiredLevel: 'Guardian',
      icon: Icons.edit,
      color: Colors.indigo,
    ),
    LevelReward(
      name: 'Eco Giant Hoodie',
      description: 'Premium organic cotton hoodie',
      requiredLevel: 'Protector',
      icon: Icons.layers,
      color: Colors.purple,
    ),
    LevelReward(
      name: 'Ultimate Eco Kit',
      description: 'T-shirt + Bottle + Hoodie + Certificate',
      requiredLevel: 'Eco Giant',
      icon: Icons.card_giftcard,
      color: Colors.amber,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    _user = await DatabaseManager.instance.getUser();
    setState(() => _isLoading = false);
  }

  bool _isUnlocked(String requiredLevel) {
    if (_user == null) return false;
    final levels = ['Seedling', 'Sprout', 'Guardian', 'Protector', 'Eco Giant'];
    final userIndex = levels.indexOf(_user!.ecoLevel);
    final requiredIndex = levels.indexOf(requiredLevel);
    return userIndex >= requiredIndex;
  }

  String _generateRedemptionCode() {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return 'EG-${List.generate(4, (_) => chars[random.nextInt(chars.length)]).join()}-${List.generate(4, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  void _showRedemptionDialog(LevelReward reward) {
    final code = _generateRedemptionCode();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem ${reward.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              reward.icon,
              size: getProportionateScreenWidth(48),
              color: reward.color,
            ),
            SizedBox(height: getProportionateScreenHeight(12)),
            Text(
              'Your Redemption Code:',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(14),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(8)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(20),
                vertical: getProportionateScreenHeight(12),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                code,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(20),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(12)),
            Text(
              'Show this code to ZOU staff to claim your reward.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: getProportionateScreenWidth(12),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelProgress = _user != null ? User.getLevelProgress(_user!.totalPoints) : 0.0;
    final pointsToNext = _user != null ? User.pointsToNextLevel(_user!.totalPoints) : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Catalog'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xfff5f5f5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUser,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // User Level Card
                    Container(
                      margin: EdgeInsets.all(getProportionateScreenWidth(16)),
                      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.teal.shade500],
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                User.getLevelIcon(_user?.ecoLevel ?? 'Seedling'),
                                size: getProportionateScreenWidth(48),
                                color: Colors.white,
                              ),
                              SizedBox(width: getProportionateScreenWidth(16)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (_user?.ecoLevel ?? 'Seedling').toUpperCase(),
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(12),
                                        color: Colors.white.withOpacity(0.8),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    Text(
                                      '${_user?.totalPoints ?? 0} points',
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(24),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: getProportionateScreenHeight(16)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: levelProgress,
                              minHeight: 10,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(8)),
                          if (pointsToNext > 0)
                            Text(
                              '$pointsToNext points to next level',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(12),
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Rewards Grid
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: getProportionateScreenWidth(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Rewards',
                            style: TextStyle(
                              fontSize: getProportionateScreenWidth(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: getProportionateScreenHeight(12)),
                          ..._rewards.map((reward) {
                            final unlocked = _isUnlocked(reward.requiredLevel);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: unlocked ? Colors.white : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: unlocked
                                    ? Border.all(color: reward.color.withOpacity(0.3))
                                    : null,
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: unlocked
                                        ? reward.color.withOpacity(0.1)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      reward.icon,
                                      size: getProportionateScreenWidth(28),
                                      color: unlocked ? reward.color : Colors.grey,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reward.name,
                                        style: TextStyle(
                                          fontSize: getProportionateScreenWidth(16),
                                          fontWeight: FontWeight.w600,
                                          color: unlocked ? Colors.black : Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                    if (unlocked)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'UNLOCKED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock, size: 12, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              reward.requiredLevel,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  reward.description,
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(13),
                                    color: unlocked ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                ),
                                trailing: unlocked
                                    ? ElevatedButton(
                                        onPressed: () => _showRedemptionDialog(reward),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: reward.color,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: const Text('Redeem'),
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    SizedBox(height: getProportionateScreenHeight(20)),
                  ],
                ),
              ),
            ),
    );
  }
}
