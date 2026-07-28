import 'dart:io';
import 'dart:math' as math;
import 'package:deep_waste/components/alert.dart';
import 'package:deep_waste/components/categories.dart';
import 'package:deep_waste/components/display_picture.dart';
import 'package:deep_waste/components/history.dart';
import 'package:deep_waste/components/home_header.dart';
import 'package:deep_waste/components/progress.dart';
import 'package:deep_waste/components/ecobot_character.dart';
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
import 'package:deep_waste/screens/SettingsScreen.dart';
import 'package:deep_waste/screens/UserScreen.dart';
import 'package:deep_waste/screens/QRScannerScreen.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = "/home_screen";

  final String? title;

  const HomeScreen({super.key, this.title});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  File? _image;
  List<Item> items = [];
  bool isLoading = false;
  User? user;
  List<DisposalRecord> recentDisposals = [];
  int todayPoints = 0;
  List<Map<String, dynamic>> leaderboardEntries = [];
  
  // Animation controllers for gamification effects
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  
  final ImagePicker imagePicker = ImagePicker();
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadData();
    _loadLeaderboard();
  }
  
  Future<void> _loadLeaderboard() async {
    try {
      final leaderboard = await DatabaseManager.instance.getLeaderboard();
      setState(() => leaderboardEntries = leaderboard.take(5).toList());
    } catch (e) {
      print('Error loading leaderboard: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Premium App Bar with Gradient
          SliverAppBar(
            expandedHeight: getProportionateScreenHeight(180),
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F766E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F766E),
                      Color(0xFF14B8A6),
                      Color(0xFF06B6D4),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                    // User info overlay
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                backgroundImage: user?.profileImage != null && user!.profileImage!.isNotEmpty
                                    ? FileImage(File(user!.profileImage!))
                                    : const AssetImage('assets/icons/icon.png') as ImageProvider,
                                child: user?.profileImage == null || user!.profileImage!.isEmpty
                                    ? const Icon(Icons.person, size: 32, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome back,',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    Text(
                                      user?.name ?? 'Guest',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                                onPressed: () {
                                  if (user != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SettingsScreen(user: user!),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => UserScreen()),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Leaderboard & Updates Carousel
                        _buildLeaderboardCarousel(),
                        
                        const SizedBox(height: 24),
                        
                        // Premium Gamification Hero Card
                        if (user != null)
                          _buildPremiumGamificationCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Section Title
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal.shade400, Colors.cyan.shade400],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quick Actions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Premium Quick Actions Grid
                        _buildPremiumQuickActions(),
                        
                        const SizedBox(height: 24),
                        
                        // Section Title
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal.shade400, Colors.cyan.shade400],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Waste Categories',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Categories(),
                        
                        const SizedBox(height: 24),
                        
                        // Recent Disposals
                        if (recentDisposals.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.teal.shade400, Colors.cyan.shade400],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recent Activity',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildRecentDisposals(),
                          const SizedBox(height: 24),
                        ],
                        
                        // Progress Section
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.teal.shade400, Colors.cyan.shade400],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Your Impact',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Progress(items: items),
                        
                        const SizedBox(height: 24),
                        
                        const History(),
                        
                        const SizedBox(height: 100), // Space for FABs
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Live AI Tutor FAB
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LiveAiPrejoinScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Live AI Tutor',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Floating Action Buttons - Fixed positioning
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live AI Tutor FAB
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, LiveAiPrejoinScreen.routeName);
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const PhosphorIcon(
                                  PhosphorIcons.robot(PhosphorIconsStyle.fill),
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Live AI Tutor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Camera FAB
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                        onPressed: () {
                          if (user == null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserScreen()),
                            );
                          } else {
                            _showCameraOptions();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCameraMenu(),
    );
  }

  Widget _buildCameraMenu() {
    return FabCircularMenu(
      ringDiameter: getProportionateScreenWidth(140),
      ringColor: const Color(0xFF06B6D4),
      ringWidth: getProportionateScreenWidth(45),
      fabSize: getProportionateScreenWidth(56),
      fabElevation: getProportionateScreenWidth(12),
      fabCloseIcon: const Icon(Icons.close, color: Colors.white),
      fabOpenIcon: const Icon(Icons.camera_alt, color: Colors.white),
      children: <Widget>[
        _buildFabMenuItem(Icons.camera_alt_outlined, _imageFromCamera),
        _buildFabMenuItem(Icons.photo_library_outlined, _imageFromGallery),
      ],
    );
  }

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF06B6D4)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _imageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF06B6D4)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _imageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFabMenuItem(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF06B6D4)),
        onPressed: () {
          if (user == null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserScreen()),
            );
          } else {
            onTap();
          }
        },
      ),
    );
  }

  Widget _buildLeaderboardCarousel() {
    if (leaderboardEntries.isEmpty) return const SizedBox.shrink();
    
    final carouselItems = [
      // Champion Podium Card
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.shade100,
              Colors.orange.shade100,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(PhosphorIcons.trophy(PhosphorIconsStyle.fill), color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '🏆 Champions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (leaderboardEntries.length >= 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 2nd place
                    _buildPodiumItem(leaderboardEntries[1], 2, 70),
                    const SizedBox(width: 12),
                    // 1st place
                    _buildPodiumItem(leaderboardEntries[0], 1, 90),
                    const SizedBox(width: 12),
                    // 3rd place
                    _buildPodiumItem(leaderboardEntries[2], 3, 70),
                  ],
                ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Can you beat them?',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Recent Updates Card
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade100,
              Colors.cyan.shade100,
              Colors.white,
            ],
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(PhosphorIcons.bell(PhosphorIconsStyle.fill), color: Colors.teal.shade700, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Latest Updates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildUpdateItem(
                Icons.eco,
                'New Feature!',
                'Live AI Tutor is now voice-activated',
                Colors.teal,
              ),
              const SizedBox(height: 12),
              _buildUpdateItem(
                Icons.card_giftcard,
                'Rewards Updated',
                'ZOU merchandise now available',
                Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildUpdateItem(
                Icons.stars,
                'Level Up!',
                'Reach Eco Giant for exclusive rewards',
                Colors.amber,
              ),
            ],
          ),
        ),
      ),
      
      // Your Progress Card
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade100,
              Colors.teal.shade100,
              Colors.white,
            ],
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(PhosphorIcons.crown(PhosphorIconsStyle.fill), color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Your Journey',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (user != null) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        User.getLevelIcon(user!.ecoLevel),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user!.ecoLevel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${user!.totalPoints} points',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PhosphorIcon(
                      PhosphorIcons.trendUp(PhosphorIconsStyle.fill),
                      color: Colors.green.shade700,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: User.getLevelProgress(user!.totalPoints) / 100,
                  backgroundColor: Colors.green.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ],
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider.builder(
          itemCount: carouselItems.length,
          options: CarouselOptions(
            height: 220,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            onPageChanged: (index, reason) {
              setState(() => _currentCarouselIndex = index);
            },
          ),
          itemBuilder: (context, index, realIdx) => carouselItems[index],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: carouselItems.asMap().entries.map((entry) {
            return Container(
              width: _currentCarouselIndex == entry.key ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentCarouselIndex == entry.key
                    ? Colors.teal
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> entry, int rank, double height) {
    final colors = [
      Colors.amber,
      Colors.grey.shade400,
      Colors.orange.shade300,
    ];
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              color: colors[rank - 1],
              size: rank == 1 ? 36 : 28,
            ),
            if (rank == 1)
              Positioned(
                top: -8,
                child: Icon(Icons.star, color: Colors.white, size: 16),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors[rank - 1].withOpacity(0.8),
                colors[rank - 1],
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  entry['name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry['totalPoints']}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateItem(IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumGamificationCard() {
    final levelProgress = User.getLevelProgress(user!.totalPoints);
    final pointsToNext = User.pointsToNextLevel(user!.totalPoints);
    final levels = ['Seedling', 'Sprout', 'Guardian', 'Protector', 'Eco Giant'];
    final currentLevelIndex = levels.indexOf(user!.ecoLevel);
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F766E),
                const Color(0xFF14B8A6),
                Colors.teal.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer effect overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, _) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(_shimmerController.value * 2 - 1, -1),
                            end: Alignment(_shimmerController.value * 2 - 1, 1),
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.all(getProportionateScreenWidth(20)),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Animated Level Badge
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                User.getLevelIcon(user!.ecoLevel),
                                size: getProportionateScreenWidth(36),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user!.ecoLevel.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(10),
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (user!.currentStreak > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            color: Colors.orangeAccent,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${user!.currentStreak} day streak',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${user!.totalPoints}',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(32),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.2),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'total points',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(12),
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: getProportionateScreenHeight(16)),
                    // Level Progress
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Level ${currentLevelIndex + 1}/5',
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(11),
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    pointsToNext > 0
                                        ? '$pointsToNext pts to go'
                                        : '🏆 Max level!',
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(11),
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  height: 12,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: levelProgress,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white,
                                                Colors.amber.shade200,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Today's Points Mini Card
                        Container(
                          padding: EdgeInsets.all(getProportionateScreenWidth(12)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber.shade200,
                                size: getProportionateScreenWidth(20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$todayPoints',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(18),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'today',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(9),
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildActionCard(
          icon: Icons.leaderboard_rounded,
          title: 'Leaderboard',
          subtitle: 'Compete & Win',
          gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade500]),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
          ),
        ),
        _buildActionCard(
          icon: Icons.card_giftcard_rounded,
          title: 'Rewards',
          subtitle: 'Claim Prizes',
          gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.pink.shade500]),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RewardsScreen()),
          ),
        ),
        _buildActionCard(
          icon: Icons.smart_toy_rounded,
          title: 'Live AI Tutor',
          subtitle: 'Video Chat',
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          badgeText: 'NEW',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LiveAiPrejoinScreen()),
          ),
        ),
        _buildActionCard(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Scan QR',
          subtitle: 'Verify Disposal',
          gradient: LinearGradient(colors: [Colors.green.shade400, Colors.teal.shade500]),
          onTap: () {
            if (user == null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserScreen()),
              );
            } else {
              _showCategoryPickerForQR();
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (badgeText != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: gradient.colors.first,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Decorative circle
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
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
