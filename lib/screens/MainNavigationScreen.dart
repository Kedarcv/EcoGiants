import 'package:deep_waste/screens/HomeScreen.dart';
import 'package:deep_waste/screens/LearningScreen.dart';
import 'package:deep_waste/screens/LeaderboardScreen.dart';
import 'package:deep_waste/screens/ProfileScreen.dart';
import 'package:deep_waste/screens/ClassifyScreen.dart';
import 'package:flutter/material.dart';

class MainNavigationScreen extends StatefulWidget {
  static const String routeName = '/main_navigation';

  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: _homeKey),
          const LeaderboardScreen(),
          LearningScreen(onQuizCompleted: _refreshHome),
          ProfileScreen(key: _profileKey),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClassifyScreen()),
          ).then((_) => _refreshHome());
        },
        backgroundColor: const Color(0xFF0D9488),
        elevation: 4,
        child: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.leaderboard_outlined, Icons.leaderboard, 'Board'),
              const SizedBox(width: 48),
              _buildNavItem(2, Icons.menu_book_outlined, Icons.menu_book, 'Learn'),
              _buildNavItem(3, Icons.person_outlined, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshHome() {
    _homeKey.currentState?.refresh();
  }

  void _refreshProfile() {
    _profileKey.currentState?.refresh();
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) _refreshHome();
        if (index == 3) _refreshProfile();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
