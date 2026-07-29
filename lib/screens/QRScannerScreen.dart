import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/models/disposal_record.dart';
import 'package:deep_waste/screens/MainNavigationScreen.dart';
import 'package:deep_waste/screens/VerificationSuccessScreen.dart';
import 'package:deep_waste/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRScannerScreen extends StatefulWidget {
  static String routeName = "/qr_scanner";
  final String expectedCategory;

  const QRScannerScreen({
    Key? key,
    required this.expectedCategory,
  }) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  bool _torchOn = false;

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final Barcode barcode = barcodes.first;
    final String? value = barcode.rawValue;

    if (value != null && value.isNotEmpty) {
      setState(() => _isProcessing = true);
      _verifyQR(value);
    }
  }

  Future<void> _verifyQR(String qrData) async {
    try {
      HapticFeedback.mediumImpact();

      final cleanData = qrData.trim();
      String qrCategory = 'General';

      final parts = cleanData.split('_');
      if (parts.length >= 3 && parts[0] == 'EG') {
        final categoryCode = parts[2].toUpperCase();
        final categoryMap = {
          'REC': 'Recyclable',
          'ORG': 'Organic',
          'EWA': 'E-Waste',
          'GEN': 'General',
          'HAZ': 'Hazardous',
        };
        qrCategory = categoryMap[categoryCode] ?? 'General';
      } else {
        final lower = cleanData.toLowerCase();
        if (lower.contains('rec') || lower.contains('plastic') || lower.contains('paper') || lower.contains('glass') || lower.contains('metal')) {
          qrCategory = 'Recyclable';
        } else if (lower.contains('org') || lower.contains('food') || lower.contains('compost')) {
          qrCategory = 'Organic';
        } else if (lower.contains('ewa') || lower.contains('tech') || lower.contains('battery') || lower.contains('device')) {
          qrCategory = 'E-Waste';
        } else if (lower.contains('haz') || lower.contains('chemical') || lower.contains('spray')) {
          qrCategory = 'Hazardous';
        } else {
          qrCategory = 'General';
        }
      }

      // Validate category match
      if (qrCategory.toLowerCase() != widget.expectedCategory.toLowerCase()) {
        _showError('Scanned QR is for $qrCategory waste, but you selected ${widget.expectedCategory}. Please scan the ${widget.expectedCategory} bin QR code.');
        return;
      }

      // Get user profile
      final user = await DatabaseManager.instance.getUser();
      if (user == null) {
        _showError('User profile not found. Please setup your profile first.');
        return;
      }

      // Check daily points cap
      final todayPoints = await DatabaseManager.instance.getTodayPoints();
      final int basePoints = User.pointsByCategory[qrCategory] ?? 10;
      if (todayPoints >= 200) {
        _showError('Daily points cap reached (200 pts/day). Come back tomorrow!');
        return;
      }

      final int streakMultiplier = _getStreakMultiplier(user.currentStreak);
      final int finalPoints = (basePoints * streakMultiplier).clamp(1, 200 - todayPoints);

      final newTotalPoints = user.totalPoints + finalPoints;
      final newLevel = User.calculateLevel(newTotalPoints);
      final bool levelUp = newLevel != user.ecoLevel;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      int newStreak = user.currentStreak;

      if (user.lastDisposalDate != null) {
        final lastDate = DateTime.parse(user.lastDisposalDate!);
        final difference = now.difference(lastDate).inDays;
        if (difference >= 1 && difference <= 2) {
          newStreak++;
        } else if (difference > 2) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      final updatedUser = user.copyWith(
        totalPoints: newTotalPoints,
        ecoLevel: newLevel,
        currentStreak: newStreak,
        maxStreak: newStreak > user.maxStreak ? newStreak : user.maxStreak,
        lastDisposalDate: todayStr,
      );

      await DatabaseManager.instance.updateUser(updatedUser);
      await DatabaseManager.instance.updateRealUserInLeaderboard(updatedUser);

      final prefs = await SharedPreferences.getInstance();
      final studentNumber = prefs.getString('student_number') ?? '';
      if (studentNumber.isNotEmpty) {
        await ApiService.instance.addPoints(
          studentNumber: studentNumber,
          points: finalPoints,
          category: qrCategory,
          itemName: 'Bin_${widget.expectedCategory}',
        );
      }

      final disposalId = '${user.id}_${DateTime.now().millisecondsSinceEpoch}';
      await DatabaseManager.instance.insertDisposal(DisposalRecord(
        id: disposalId,
        category: qrCategory,
        pointsAwarded: finalPoints,
        timestamp: DateTime.now().toIso8601String(),
        qrCode: cleanData,
        binName: 'ZOU ${widget.expectedCategory} Bin',
      ));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationSuccessScreen(
            pointsAwarded: finalPoints,
            totalPoints: newTotalPoints,
            ecoLevel: newLevel,
            levelUp: levelUp,
            category: qrCategory,
            streak: newStreak,
            basePoints: basePoints,
            multiplier: streakMultiplier,
          ),
        ),
      );
    } catch (e) {
      _showError('Error processing QR verification: $e');
    }
  }

  int _getStreakMultiplier(int streak) {
    if (streak >= 7) return 3;
    if (streak >= 3) return 2;
    return 1;
  }

  void _showError(String message) {
    setState(() => _isProcessing = false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bin Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isProcessing = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
            ),
            child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isProcessing = true);
      final BarcodeCapture? capture = await controller.analyzeImage(image.path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? qrData = capture.barcodes.first.rawValue;
        if (qrData != null && qrData.isNotEmpty) {
          await _verifyQR(qrData);
          return;
        }
      }

      // Fallback if mobile_scanner gallery analysis didn't extract string
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR detected in image. Enter code manually below.'),
            duration: Duration(seconds: 3),
          ),
        );
        await _showManualEntryDialog();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      await _showManualEntryDialog();
    }
  }

  Future<void> _showManualEntryDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Manual QR Verification', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter QR code data or bin code:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'e.g. EG_BIN001_${widget.expectedCategory.substring(0, 3).toUpperCase()}_1700000000_ABC',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
            ),
            child: const Text('Verify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isProcessing = true);
      await _verifyQR(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            }
          },
        ),
        title: const Text(
          'Scan Bin QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            tooltip: 'Return to Home',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              controller.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Live Camera Barcode Scanner
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Central Cutout Scanner Overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0D9488), width: 3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Top Header Box
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  const Text(
                    'Point camera at the QR code on bin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Target Bin: ',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        widget.expectedCategory,
                        style: const TextStyle(
                          color: Color(0xFF14B8A6),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF0D9488)),
                    SizedBox(height: 16),
                    Text(
                      'Verifying Bin QR…',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Action Buttons
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library, size: 22),
                    label: const Text(
                      'Scan QR from Photo Gallery',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard, size: 22),
                    label: const Text(
                      'Enter QR Code Manually',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white60, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
