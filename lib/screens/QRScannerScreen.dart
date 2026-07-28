import 'dart:math';
import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/User.dart';
import 'package:deep_waste/models/disposal_record.dart';
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
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
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
      controller.stop();
      _verifyQR(value);
    }
  }

  Future<void> _verifyQR(String qrData) async {
    try {
      HapticFeedback.mediumImpact();

      // Parse QR format: EG_{BIN_ID}_{CATEGORY}_{TIMESTAMP}_{CHECKSUM}
      final parts = qrData.split('_');
      if (parts.length < 5 || parts[0] != 'EG') {
        _showError('Invalid QR code format');
        return;
      }

      final String binId = parts[1];
      final String categoryCode = parts[2];
      final String timestampStr = parts[3];

      // Map category code to name
      final categoryMap = {
        'REC': 'Recyclable',
        'ORG': 'Organic',
        'EWA': 'E-Waste',
        'GEN': 'General',
        'HAZ': 'Hazardous',
      };
      final String qrCategory = categoryMap[categoryCode] ?? 'General';

      // Check if QR category matches expected classification
      if (qrCategory.toLowerCase() != widget.expectedCategory.toLowerCase()) {
        _showError('This bin is for $qrCategory, not ${widget.expectedCategory}. Please find the correct bin.');
        return;
      }

      // Check QR expiry (30 days for printed bin QR codes)
      final int qrTimestamp = int.tryParse(timestampStr) ?? 0;
      final int nowTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowTimestamp - qrTimestamp > 2592000) {
        _showError('QR code has expired. Please get a new QR code from the bin.');
        return;
      }

      // Get user
      final user = await DatabaseManager.instance.getUser();
      if (user == null) {
        _showError('User not found. Please create a profile first.');
        return;
      }

      // Check daily points cap (200/day)
      final todayPoints = await DatabaseManager.instance.getTodayPoints();
      final int basePoints = User.pointsByCategory[qrCategory] ?? 10;
      if (todayPoints >= 200) {
        _showError('Daily points cap reached (200). Come back tomorrow!');
        return;
      }

      // Apply streak multiplier
      final int streakMultiplier = _getStreakMultiplier(user.currentStreak);
      final int finalPoints = min(basePoints * streakMultiplier, 200 - todayPoints);

      // Check for level up
      final newTotalPoints = user.totalPoints + finalPoints;
      final newLevel = User.calculateLevel(newTotalPoints);
      final bool levelUp = newLevel != user.ecoLevel;

      // Update streak
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

      // Update user
      final updatedUser = user.copyWith(
        totalPoints: newTotalPoints,
        ecoLevel: newLevel,
        currentStreak: newStreak,
        maxStreak: newStreak > user.maxStreak ? newStreak : user.maxStreak,
        lastDisposalDate: todayStr,
      );

      await DatabaseManager.instance.updateUser(updatedUser);
      await DatabaseManager.instance.updateRealUserInLeaderboard(updatedUser);

      // Sync points to backend
      final prefs = await SharedPreferences.getInstance();
      final studentNumber = prefs.getString('student_number') ?? '';
      if (studentNumber.isNotEmpty) {
        await ApiService.instance.addPoints(
          studentNumber: studentNumber,
          points: finalPoints,
          category: qrCategory,
          itemName: binId,
        );
      }

      // Save disposal record
      final disposalId = '${user.id}_${DateTime.now().millisecondsSinceEpoch}';
      await DatabaseManager.instance.insertDisposal(DisposalRecord(
        id: disposalId,
        category: qrCategory,
        pointsAwarded: finalPoints,
        timestamp: DateTime.now().toIso8601String(),
        qrCode: qrData,
        binName: binId,
      ));

      // Navigate to success screen
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
            multiplier: streakMultiplier > 1 ? streakMultiplier : null,
          ),
        ),
      );
    } catch (e) {
      _showError('Verification failed: $e');
    }
  }

  int _getStreakMultiplier(int streak) {
    if (streak >= 30) return 2;
    if (streak >= 14) return 2;
    if (streak >= 7) return 2;
    if (streak >= 3) return 2;
    return 1;
  }

  void _showError(String message) {
    setState(() => _isProcessing = false);
    controller.start();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Scanner overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
            ),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          // Instructions
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 80),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Scan the QR code on the bin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: getProportionateScreenWidth(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expected: ${widget.expectedCategory}',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: getProportionateScreenWidth(14),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.greenAccent,
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Verifying...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          // Bottom action buttons
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard, size: 20),
                    label: const Text('Enter QR Code Manually'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library, size: 20),
                    label: const Text('Pick from Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Future<void> _showManualEntryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter QR Code Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste or type the QR code data below.',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                hintText: 'EG_BIN001_REC_1700000000_ABC123',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isProcessing = true);
      await _verifyQR(result);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image selected. Enter the QR code data manually.'),
          duration: Duration(seconds: 3),
        ),
      );
      await _showManualEntryDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }
}
