import 'package:deep_waste/components/ecobot_character.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/screens/LessonQuizScreen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearningScreen extends StatefulWidget {
  static const String routeName = '/learning';
  final VoidCallback? onQuizCompleted;

  const LearningScreen({Key? key, this.onQuizCompleted}) : super(key: key);

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with TickerProviderStateMixin {
  User? user;
  bool isLoading = true;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  Set<int> _completedLessonIds = {};

  final List<Map<String, dynamic>> _lessons = [
    {
      'id': 1,
      'title': 'Waste Basics',
      'subtitle': 'Learn about waste types',
      'icon': Icons.delete_outline,
      'color': const Color(0xFF6B7280),
      'assetImg': 'assets/images/trash.png',
      'lottie': 'assets/lottie/recycling.json',
      'xp': 50,
    },
    {
      'id': 2,
      'title': 'Recycling 101',
      'subtitle': 'Master paper, plastic & metal',
      'icon': Icons.recycling,
      'color': const Color(0xFF3B82F6),
      'assetImg': 'assets/images/plastic.png',
      'lottie': 'assets/lottie/recycling.json',
      'xp': 75,
    },
    {
      'id': 3,
      'title': 'Composting',
      'subtitle': 'Turn organic waste into garden gold',
      'icon': Icons.eco,
      'color': const Color(0xFF10B981),
      'assetImg': 'assets/images/background.png',
      'lottie': 'assets/lottie/recycling.json',
      'xp': 100,
    },
    {
      'id': 4,
      'title': 'E-Waste',
      'subtitle': 'Handle electronics & batteries safely',
      'icon': Icons.devices,
      'color': const Color(0xFF8B5CF6),
      'assetImg': 'assets/images/cardboard.png',
      'lottie': 'assets/lottie/recycling.json',
      'xp': 120,
    },
    {
      'id': 5,
      'title': 'Hazardous Waste',
      'subtitle': 'Safety first with chemicals & glass',
      'icon': Icons.warning,
      'color': const Color(0xFFEF4444),
      'assetImg': 'assets/images/glass.png',
      'lottie': 'assets/lottie/recycling.json',
      'xp': 150,
    },
  ];

  final List<Map<String, String>> _tips = [
    {
      'title': 'Did you know?',
      'tip':
          'Recycling one aluminum can saves enough energy to run a TV for 3 hours!',
    },
    {
      'title': 'Fun fact',
      'tip': 'A glass bottle takes 4,000 years to decompose in a landfill.',
    },
    {
      'title': 'Pro tip',
      'tip':
          'Rinse containers before recycling to avoid contaminating other materials.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      user = await DatabaseManager.instance.getUser();
      final prefs = await SharedPreferences.getInstance();
      final savedCompleted =
          prefs.getStringList('completed_lesson_ids') ?? ['1', '2'];
      _completedLessonIds = savedCompleted.map((e) => int.parse(e)).toSet();
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _markLessonCompleted(int lessonId) async {
    setState(() {
      _completedLessonIds.add(lessonId);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'completed_lesson_ids',
      _completedLessonIds.map((e) => e.toString()).toList(),
    );
  }

  void _startLesson(Map<String, dynamic> lesson) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonQuizScreen(
          lessonId: lesson['id'],
          lessonTitle: lesson['title'],
          lessonTopic: lesson['title'],
          xpReward: lesson['xp'],
        ),
      ),
    );

    if (result == true) {
      await _markLessonCompleted(lesson['id']);
      await _loadData();
      if (widget.onQuizCompleted != null) widget.onQuizCompleted!();
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildEcoBotIntro(),
                        const SizedBox(height: 24),
                        _buildDailyTip(),
                        const SizedBox(height: 24),
                        _buildLessonPath(),
                        const SizedBox(height: 24),
                        _buildAchievements(),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top + 10;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Eco Academy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 4),
                Text(
                  '${user?.totalPoints ?? 0} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcoBotIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnimation.value),
                  child: const EcoBotCharacter(
                    pose: EcoBotPose.waving,
                    size: 80,
                    animated: true,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hey there! I'm EcoBot!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "All 5 lessons & quizzes are unlocked for you! Tap any lesson to test your knowledge & earn XP!",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTip() {
    final tip = _tips[DateTime.now().day % _tips.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title']!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip['tip']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF78350F),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPath() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lesson Path (All Unlocked)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '5 / 5 Unlocked',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_lessons.length, (index) {
          final lesson = _lessons[index];
          final isLast = index == _lessons.length - 1;
          return _buildLessonItem(lesson, index, isLast);
        }),
      ],
    );
  }

  Widget _buildLessonItem(
      Map<String, dynamic> lesson, int index, bool isLast) {
    final lessonId = lesson['id'] as int;
    final completed = _completedLessonIds.contains(lessonId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFF10B981)
                    : lesson['color'] as Color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (completed
                            ? const Color(0xFF10B981)
                            : (lesson['color'] as Color))
                        .withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: completed
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 3,
                height: 44,
                color:
                    completed ? const Color(0xFF10B981) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => _startLesson(lesson),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      lesson['assetImg'],
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (lesson['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          lesson['icon'] as IconData,
                          color: lesson['color'] as Color,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              lesson['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (completed) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  color: Color(0xFF10B981), size: 16),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lesson['subtitle'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${lesson['xp']} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    final completedCount = _completedLessonIds.length;
    final totalCount = _lessons.length;
    final progressFraction = (completedCount / totalCount).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements (Realtime)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: Lottie.asset(
                  completedCount >= totalCount
                      ? 'assets/lottie/levelup.json'
                      : 'assets/lottie/celebration.json',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events_rounded,
                    size: 72,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$completedCount / $totalCount Lessons Completed',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                completedCount >= totalCount
                    ? '🏆 Eco Master Status Achieved! All quizzes cleared!'
                    : 'Complete remaining quizzes to unlock Eco Master rank!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progressFraction * 100).toInt()}% Completed',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
