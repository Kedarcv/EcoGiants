import 'package:deep_waste/components/ecobot_character.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/screens/LessonQuizScreen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LearningScreen extends StatefulWidget {
  static const String routeName = '/learning';
  final VoidCallback? onQuizCompleted;

  const LearningScreen({Key? key, this.onQuizCompleted}) : super(key: key);

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> with TickerProviderStateMixin {
  User? user;
  bool isLoading = true;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  final List<Map<String, dynamic>> _lessons = [
    {
      'id': 1,
      'title': 'Waste Basics',
      'subtitle': 'Learn about waste types',
      'icon': Icons.delete_outline,
      'color': Color(0xFF6B7280),
      'lottie': 'assets/lottie/recycling.json',
      'completed': true,
      'xp': 50,
    },
    {
      'id': 2,
      'title': 'Recycling 101',
      'subtitle': 'Master the recycling process',
      'icon': Icons.recycling,
      'color': Color(0xFF3B82F6),
      'lottie': 'assets/lottie/recycling.json',
      'completed': true,
      'xp': 75,
    },
    {
      'id': 3,
      'title': 'Composting',
      'subtitle': 'Turn waste into garden gold',
      'icon': Icons.eco,
      'color': Color(0xFF10B981),
      'lottie': 'assets/lottie/recycling.json',
      'completed': false,
      'xp': 100,
    },
    {
      'id': 4,
      'title': 'E-Waste',
      'subtitle': 'Handle electronics safely',
      'icon': Icons.devices,
      'color': Color(0xFF8B5CF6),
      'lottie': 'assets/lottie/recycling.json',
      'completed': false,
      'xp': 120,
    },
    {
      'id': 5,
      'title': 'Hazardous Waste',
      'subtitle': 'Safety first with chemicals',
      'icon': Icons.warning,
      'color': Color(0xFFEF4444),
      'lottie': 'assets/lottie/recycling.json',
      'completed': false,
      'xp': 150,
    },
  ];

  final List<Map<String, String>> _tips = [
    {
      'title': 'Did you know?',
      'tip': 'Recycling one aluminum can saves enough energy to run a TV for 3 hours!',
    },
    {
      'title': 'Fun fact',
      'tip': 'A glass bottle takes 4,000 years to decompose in a landfill.',
    },
    {
      'title': 'Pro tip',
      'tip': 'Rinse containers before recycling to avoid contaminating other materials.',
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
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
            'Learn',
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
                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${user?.totalPoints ?? 0} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
                  "Ready to learn about waste management? Let's make the planet greener together!",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
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
          const Icon(Icons.lightbulb, color: Color(0xFFF59E0B), size: 24),
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
        const Text(
          'Lesson Path',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
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

  Widget _buildLessonItem(Map<String, dynamic> lesson, int index, bool isLast) {
    final completed = lesson['completed'] as bool;
    final isLocked = index > 0 && !(_lessons[index - 1]['completed'] as bool);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFF10B981)
                    : isLocked
                        ? Colors.grey.shade300
                        : lesson['color'] as Color,
                shape: BoxShape.circle,
                boxShadow: completed
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: completed
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : isLocked
                        ? Icon(Icons.lock, color: Colors.grey.shade500, size: 18)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: completed ? const Color(0xFF10B981) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: isLocked ? null : () => _startLesson(lesson),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isLocked
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (lesson['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      lesson['icon'] as IconData,
                      color: lesson['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson['title'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isLocked ? Colors.grey : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${lesson['xp']} XP',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
    final completedCount = _lessons.where((l) => l['completed'] as bool).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Lottie.asset(
                  'assets/lottie/celebration.json',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$completedCount / ${_lessons.length} Lessons',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete all lessons to become an Eco Master!',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: completedCount / _lessons.length,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
            ],
          ),
        ),
      ],
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
    
    // Refresh data if lesson was completed
    if (result == true) {
      _loadData();
      widget.onQuizCompleted?.call();
    }
  }
}
