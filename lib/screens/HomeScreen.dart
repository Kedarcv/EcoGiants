import 'dart:io';
import 'package:deep_waste/components/alert.dart';
import 'package:deep_waste/components/categories.dart';
import 'package:deep_waste/components/display_picture.dart';
import 'package:deep_waste/components/history.dart';
import 'package:deep_waste/components/home_header.dart';
import 'package:deep_waste/components/progress.dart';
import 'package:deep_waste/constants/app_properties.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/Item.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/models/disposal_record.dart';
import 'package:deep_waste/screens/DisposalHistoryScreen.dart';
import 'package:deep_waste/screens/EcoBotChatScreen.dart';
import 'package:deep_waste/screens/LeaderboardScreen.dart';
import 'package:deep_waste/screens/LiveAiPrejoinScreen.dart';
import 'package:deep_waste/screens/RewardsScreen.dart';
import 'package:deep_waste/screens/UserScreen.dart';
import 'package:deep_waste/screens/QRScannerScreen.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = "/home_screen";

  final String? title;

  const HomeScreen({super.key, this.title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  List<Item> items = [];
  bool isLoading = false;
  User? user;
  List<DisposalRecord> recentDisposals = [];
  int todayPoints = 0;

  final ImagePicker imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await getItems();
    await getUserInfo();
    await getRecentDisposals();
    await getTodayPoints();
    setState(() => isLoading = false);
  }

  Future<void> _imageFromCamera() async {
    try {
      final capturedImage =
          await imagePicker.pickImage(source: ImageSource.camera);

      if (capturedImage == null) {
        showAlert(
          bContext: context,
          title: "Error choosing file",
          content: "No file was selected",
        );
        return;
      }

      final imagePath = File(capturedImage.path);

      setState(() => _image = imagePath);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPicture(image: _image!, items: items),
        ),
      );
    } catch (e) {
      showAlert(
        bContext: context,
        title: "Error capturing image file",
        content: e.toString(),
      );
    }
  }

  Future<void> _imageFromGallery() async {
    final uploadedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (uploadedImage == null) {
      showAlert(
        bContext: context,
        title: "Error choosing file",
        content: "No file was selected",
      );
      return;
    }

    final imagePath = File(uploadedImage.path);

    setState(() => _image = imagePath);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisplayPicture(image: _image!, items: items),
      ),
    );
  }

  Future<void> getUserInfo() async {
    user = await DatabaseManager.instance.getUser();
  }

  Future<void> getItems() async {
    items = await DatabaseManager.instance.getItems();
  }

  Future<void> getRecentDisposals() async {
    recentDisposals = await DatabaseManager.instance.getDisposals(limit: 3);
  }

  Future<void> getTodayPoints() async {
    todayPoints = await DatabaseManager.instance.getTodayPoints();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return Colors.blue;
      case 'organic':
        return Colors.green;
      case 'e-waste':
        return Colors.purple;
      case 'general':
        return Colors.grey;
      case 'hazardous':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'e-waste':
        return Icons.devices;
      case 'general':
        return Icons.delete;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: white,
      floatingActionButton: FabCircularMenu(
        ringDiameter: getProportionateScreenWidth(130),
        ringColor: const Color(0xff69c0dc),
        ringWidth: getProportionateScreenWidth(40),
        fabSize: getProportionateScreenWidth(44),
        fabElevation: getProportionateScreenWidth(8),
        fabCloseIcon: const Icon(Icons.close),
        fabOpenIcon: const Icon(Icons.photo),
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {
              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserScreen()),
                );
              } else {
                _imageFromCamera();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserScreen()),
                );
              } else {
                _imageFromGallery();
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          HomeHeader(user: user),
                          SizedBox(height: getProportionateScreenHeight(15)),
                          
                          // Gamification Stats Card
                          if (user != null)
                            _buildGamificationCard(),
                          
                          SizedBox(height: getProportionateScreenHeight(15)),
                          
                          // Quick Actions
                          _buildQuickActions(),
                          
                          SizedBox(height: getProportionateScreenHeight(15)),
                          
                          const Categories(),
                          
                          SizedBox(height: getProportionateScreenHeight(15)),
                          
                          // Recent Disposals
                          if (recentDisposals.isNotEmpty)
                            _buildRecentDisposals(),
                          
                          SizedBox(height: getProportionateScreenHeight(15)),
                          
                          Progress(items: items),
                          
                          SizedBox(height: getProportionateScreenHeight(15)),
                          
                          const History(),
                          
                          SizedBox(width: getProportionateScreenWidth(20)),
                        ],
                      ),
                    ),
                  ),
          ),
          // Floating chat button — above the camera FAB
          Positioned(
            right: 20,
            bottom: 88,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EcoBotChatScreen()),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Level Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    User.getLevelIcon(user!.ecoLevel),
                    size: getProportionateScreenWidth(28),
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user!.ecoLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(11),
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      '${user!.totalPoints} points',
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(22),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Streak
              if (user!.currentStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${user!.currentStreak}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: User.getLevelProgress(user!.totalPoints),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                User.pointsToNextLevel(user!.totalPoints) > 0
                    ? '${User.pointsToNextLevel(user!.totalPoints)} pts to next level'
                    : 'Max level reached!',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(12),
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                'Today: $todayPoints pts',
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(12),
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.leaderboard,
            label: 'Leaderboard',
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
          ),
          SizedBox(width: getProportionateScreenWidth(10)),
          _buildActionButton(
            icon: Icons.card_giftcard,
            label: 'Rewards',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RewardsScreen()),
              );
            },
          ),
          SizedBox(width: getProportionateScreenWidth(10)),
          _buildActionButton(
            icon: Icons.smart_toy,
            label: 'Live AI',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LiveAiPrejoinScreen()),
              );
            },
          ),
          SizedBox(width: getProportionateScreenWidth(10)),
          _buildActionButton(
            icon: Icons.qr_code_scanner,
            label: 'Scan QR',
            color: Colors.green,
            onTap: () {
              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserScreen()),
                );
              } else {
                // Show category picker before QR scan
                _showCategoryPickerForQR();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(12)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: getProportionateScreenHeight(4)),
              Text(
                label,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(11),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPickerForQR() {
    final categories = ['Recyclable', 'Organic', 'E-Waste', 'General', 'Hazardous'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Waste Category',
              style: TextStyle(
                fontSize: getProportionateScreenWidth(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(16)),
            ...categories.map((cat) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(cat).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(cat),
                  color: _getCategoryColor(cat),
                ),
              ),
              title: Text(cat),
              trailing: Text(
                '+${User.pointsByCategory[cat] ?? 10} pts',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QRScannerScreen(expectedCategory: cat),
                  ),
                ).then((_) => _loadData());
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDisposals() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Disposals",
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(18),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DisposalHistoryScreen()),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(13),
                    color: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          ...recentDisposals.map((record) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(getProportionateScreenWidth(12)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(record.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(record.category),
                    color: _getCategoryColor(record.category),
                    size: 20,
                  ),
                ),
                SizedBox(width: getProportionateScreenWidth(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.category,
                        style: TextStyle(
                          fontSize: getProportionateScreenWidth(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (record.binName != null)
                        Text(
                          'Bin: ${record.binName}',
                          style: TextStyle(
                            fontSize: getProportionateScreenWidth(12),
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${record.pointsAwarded}',
                    style: TextStyle(
                      fontSize: getProportionateScreenWidth(13),
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
