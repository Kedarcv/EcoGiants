import 'dart:math';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:flutter/material.dart';

class RewardItem {
  final String id;
  final String name;
  final String description;
  final String category; // 'Tech', 'Merch', 'Perks'
  final int points;
  final String requiredLevel;
  final IconData icon;
  final Color color;
  final bool isFeatured;

  RewardItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.points,
    required this.requiredLevel,
    required this.icon,
    required this.color,
    this.isFeatured = false,
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
  String _selectedCategoryFilter = 'All';

  final List<RewardItem> _allRewards = [
    // --- TECH & STUDY GADGETS ---
    RewardItem(
      id: 'tech_01',
      name: 'ZOU Study Laptop (Refurbished Core i5)',
      description: 'Fully equipped laptop for coursework, research & assignments.',
      category: 'Tech',
      points: 5000,
      requiredLevel: 'Eco Giant',
      icon: Icons.laptop_mac,
      color: const Color(0xFF2563EB),
      isFeatured: true,
    ),
    RewardItem(
      id: 'tech_02',
      name: 'Noise-Canceling Study Headphones',
      description: 'Focus during exams and quiet study hours at ZOU library.',
      category: 'Tech',
      points: 1500,
      requiredLevel: 'Protector',
      icon: Icons.headphones,
      color: const Color(0xFF7C3AED),
      isFeatured: true,
    ),
    RewardItem(
      id: 'tech_03',
      name: '20,000mAh Solar Power Bank',
      description: 'High capacity solar charger for campus and study sessions.',
      category: 'Tech',
      points: 800,
      requiredLevel: 'Guardian',
      icon: Icons.battery_charging_full,
      color: const Color(0xFF0284C7),
    ),
    RewardItem(
      id: 'tech_04',
      name: '1TB External Hard Drive',
      description: 'Store all your academic projects, books & study materials.',
      category: 'Tech',
      points: 1200,
      requiredLevel: 'Guardian',
      icon: Icons.sd_storage,
      color: const Color(0xFF0D9488),
    ),

    // --- ZOU CAMPUS MERCH ---
    RewardItem(
      id: 'merch_01',
      name: 'ZOU Eco-Giants Hoodie',
      description: 'Premium organic cotton embroidered ZOU student hoodie.',
      category: 'Merch',
      points: 600,
      requiredLevel: 'Sprout',
      icon: Icons.checkroom,
      color: const Color(0xFF059669),
      isFeatured: true,
    ),
    RewardItem(
      id: 'merch_02',
      name: 'ZOU Green Innovation Backpack',
      description: 'Durable eco-friendly laptop backpack with extra compartments.',
      category: 'Merch',
      points: 500,
      requiredLevel: 'Sprout',
      icon: Icons.backpack,
      color: const Color(0xFFD97706),
    ),
    RewardItem(
      id: 'merch_03',
      name: 'Eco-Giants Embroidered Cap',
      description: 'Official ZOU RII Week Hackathon student cap.',
      category: 'Merch',
      points: 300,
      requiredLevel: 'Seedling',
      icon: Icons.sports_baseball,
      color: const Color(0xFFDC2626),
    ),
    RewardItem(
      id: 'merch_04',
      name: 'Stainless Steel Thermal Mug',
      description: '500ml vacuum insulated mug for hot coffee or cold water.',
      category: 'Merch',
      points: 250,
      requiredLevel: 'Seedling',
      icon: Icons.coffee,
      color: const Color(0xFF4F46E5),
    ),

    // --- STUDENT INCENTIVES & PERKS ---
    RewardItem(
      id: 'perk_01',
      name: 'ZOU Bookstore & Exam Voucher (\$20)',
      description: 'Redeem for course textbooks, exam fees, or stationery.',
      category: 'Perks',
      points: 1000,
      requiredLevel: 'Guardian',
      icon: Icons.card_giftcard,
      color: const Color(0xFF16A34A),
      isFeatured: true,
    ),
    RewardItem(
      id: 'perk_02',
      name: '10GB Student Data Bundle',
      description: 'High-speed internet bundle for online research & lectures.',
      category: 'Perks',
      points: 400,
      requiredLevel: 'Sprout',
      icon: Icons.wifi,
      color: const Color(0xFF2563EB),
    ),
    RewardItem(
      id: 'perk_03',
      name: 'Campus Cafeteria Meal Pass (5 Meals)',
      description: 'Free nutritious meals at ZOU campus cafeteria.',
      category: 'Perks',
      points: 350,
      requiredLevel: 'Seedling',
      icon: Icons.restaurant,
      color: const Color(0xFFEA580C),
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

  bool _isUnlocked(RewardItem item) {
    if (_user == null) return false;
    return _user!.totalPoints >= item.points;
  }

  String _generateRedemptionCode() {
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return 'ZOU-${List.generate(4, (_) => chars[random.nextInt(chars.length)]).join()}-${List.generate(4, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  void _showRedemptionDialog(RewardItem reward) {
    final code = _generateRedemptionCode();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Claim ${reward.name}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: reward.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                reward.icon,
                size: 52,
                color: reward.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Student Claim Code:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Present this code at ZOU Student Affairs / Green Office to receive your ${reward.name}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final levelProgress =
        _user != null ? User.getLevelProgress(_user!.totalPoints) : 0.0;
    final userPoints = _user?.totalPoints ?? 0;

    final filteredRewards = _allRewards.where((r) {
      if (_selectedCategoryFilter == 'All') return true;
      return r.category == _selectedCategoryFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Student Rewards Store',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUser,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner Card
                    _buildHeaderBanner(userPoints, levelProgress),

                    const SizedBox(height: 16),

                    // Category Filter Pills
                    _buildCategoryFilterTabs(),

                    const SizedBox(height: 16),

                    // Rewards List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Available Incentives (${filteredRewards.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredRewards.length,
                      itemBuilder: (context, index) {
                        final item = filteredRewards[index];
                        final unlocked = _isUnlocked(item);

                        return _buildRewardCard(item, unlocked);
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderBanner(int userPoints, double levelProgress) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                User.getLevelIcon(_user?.ecoLevel ?? 'Seedling'),
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_user?.ecoLevel ?? 'Seedling').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$userPoints Eco Points',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: levelProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sort waste on campus to earn points & unlock student rewards!',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterTabs() {
    final categories = [
      {'id': 'All', 'label': 'All Rewards', 'icon': Icons.grid_view},
      {'id': 'Tech', 'label': 'Laptop & Tech', 'icon': Icons.laptop},
      {'id': 'Merch', 'label': 'ZOU Merch', 'icon': Icons.checkroom},
      {'id': 'Perks', 'label': 'Student Perks', 'icon': Icons.card_giftcard},
    ];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final selected = _selectedCategoryFilter == cat['id'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: selected,
              showCheckmark: false,
              avatar: Icon(
                cat['icon'] as IconData,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF0F172A),
              ),
              label: Text(
                cat['label'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: selected ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              selectedColor: const Color(0xFF0D9488),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? const Color(0xFF0D9488) : Colors.grey.shade300,
                width: 1.5,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategoryFilter = cat['id'] as String;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardCard(RewardItem item, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked ? item.color.withOpacity(0.4) : Colors.grey.shade200,
          width: unlocked ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (item.isFeatured) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 18,
                        color: item.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.points} pts',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: unlocked ? () => _showRedemptionDialog(item) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: unlocked
                              ? item.color
                              : Colors.grey.shade200,
                          foregroundColor: unlocked ? Colors.white : Colors.grey.shade500,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: unlocked ? 2 : 0,
                        ),
                        child: Text(
                          unlocked ? 'Claim Reward' : 'Need ${item.points} pts',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
