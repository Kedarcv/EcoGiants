import 'package:confetti/confetti.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/screens/MainNavigationScreen.dart';
import 'package:flutter/material.dart';

class VerificationSuccessScreen extends StatefulWidget {
  static String routeName = "/verification_success";
  final int pointsAwarded;
  final int totalPoints;
  final String ecoLevel;
  final bool levelUp;
  final String category;
  final int streak;
  final int basePoints;
  final int? multiplier;

  const VerificationSuccessScreen({
    Key? key,
    required this.pointsAwarded,
    required this.totalPoints,
    required this.ecoLevel,
    required this.levelUp,
    required this.category,
    required this.streak,
    required this.basePoints,
    this.multiplier,
  }) : super(key: key);

  @override
  State<VerificationSuccessScreen> createState() => _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _showPoints = false;
  bool _showTotal = false;
  bool _showLevel = false;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _scaleController.forward();

    // Staggered animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showPoints = true);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showTotal = true);
    });
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _showLevel = true);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelProgress = User.getLevelProgress(widget.totalPoints);
    final pointsToNext = User.pointsToNextLevel(widget.totalPoints);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                gravity: 0.2,
                colors: const [
                  Colors.green,
                  Colors.teal,
                  Colors.lightGreen,
                  Colors.yellow,
                  Colors.orange,
                ],
              ),
            ),
            // Top Close / Home Button
            Positioned(
              top: 12,
              left: 12,
              child: CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF0F172A)),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: getProportionateScreenWidth(30),
                ),
                child: Column(
                  children: [
                    SizedBox(height: getProportionateScreenHeight(40)),
                    // Success Icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(24)),
                    Text(
                      'Disposal Verified!',
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(28),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(8)),
                    Text(
                      'Great job disposing ${widget.category} properly!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: getProportionateScreenWidth(16),
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(30)),
                    // Points Awarded Card
                    AnimatedOpacity(
                      opacity: _showPoints ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        width: double.infinity,
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
                        child: Column(
                          children: [
                            Text(
                              '+${widget.pointsAwarded}',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(48),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'POINTS EARNED',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(14),
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 2,
                              ),
                            ),
                            if (widget.multiplier != null && widget.multiplier! > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${widget.multiplier}x STREAK BONUS!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Base: ${widget.basePoints} pts',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(12),
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(20)),
                    // Streak Info
                    if (widget.streak > 1)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: getProportionateScreenWidth(16),
                          vertical: getProportionateScreenHeight(12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.orange, size: getProportionateScreenWidth(24)),
                            SizedBox(width: getProportionateScreenWidth(8)),
                            Text(
                              '${widget.streak}-day streak!',
                              style: TextStyle(
                                fontSize: getProportionateScreenWidth(16),
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: getProportionateScreenHeight(20)),
                    // Total Points
                    AnimatedOpacity(
                      opacity: _showTotal ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Points',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(16),
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${widget.totalPoints}',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(24),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: getProportionateScreenHeight(12)),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: levelProgress,
                                minHeight: 10,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.green.shade400,
                                ),
                              ),
                            ),
                            SizedBox(height: getProportionateScreenHeight(8)),
                            if (pointsToNext > 0)
                              Text(
                                '$pointsToNext points to next level',
                                style: TextStyle(
                                  fontSize: getProportionateScreenWidth(12),
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(20)),
                    // Level Info
                    AnimatedOpacity(
                      opacity: _showLevel ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              User.getLevelIcon(widget.ecoLevel),
                              size: getProportionateScreenWidth(40),
                              color: Colors.teal,
                            ),
                            SizedBox(width: getProportionateScreenWidth(12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.ecoLevel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(14),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  if (widget.levelUp)
                                    Row(
                                      children: [
                                        Icon(Icons.celebration, color: Colors.orange, size: getProportionateScreenWidth(18)),
                                        SizedBox(width: 4),
                                        Text(
                                          'LEVEL UP!',
                                          style: TextStyle(
                                            fontSize: getProportionateScreenWidth(18),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.celebration, color: Colors.orange, size: getProportionateScreenWidth(18)),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(30)),
                    // Return to Home Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home_rounded, size: 24),
                        label: const Text(
                          'Return to Home Dashboard',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
