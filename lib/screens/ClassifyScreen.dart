import 'dart:io';
import 'package:deep_waste/screens/BinMapScreen.dart';
import 'package:deep_waste/screens/QRScannerScreen.dart';
import 'package:deep_waste/services/nvidia_vision_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ClassifyScreen extends StatefulWidget {
  static const String routeName = '/classify';

  const ClassifyScreen({Key? key}) : super(key: key);

  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen> {
  File? _image;
  String? _classifiedCategory;
  String? _itemName;
  String? _binColor;
  String? _disposalTip;
  double? _confidence;
  bool _isClassifying = false;
  bool _showResult = false;

  final Map<String, Map<String, dynamic>> _categoryInfo = {
    'Recyclable': {
      'icon': Icons.recycling,
      'color': Color(0xFF3B82F6),
      'bgColor': Color(0xFFEFF6FF),
      'description': 'This item can be recycled! Place it in the blue recycling bin.',
      'points': 30,
      'binLabel': 'Blue Recycling Bin',
    },
    'Organic': {
      'icon': Icons.eco,
      'color': Color(0xFF10B981),
      'bgColor': Color(0xFFECFDF5),
      'description': 'This is organic waste! Place it in the green compost bin.',
      'points': 20,
      'binLabel': 'Green Compost Bin',
    },
    'E-Waste': {
      'icon': Icons.devices,
      'color': Color(0xFF8B5CF6),
      'bgColor': Color(0xFFF5F3FF),
      'description': 'This is electronic waste! Take it to a special e-waste collection point.',
      'points': 40,
      'binLabel': 'Purple E-Waste Bin',
    },
    'Hazardous': {
      'icon': Icons.warning,
      'color': Color(0xFFEF4444),
      'bgColor': Color(0xFFFEF2F2),
      'description': 'This is hazardous waste! Handle with care and take to a designated facility.',
      'points': 50,
      'binLabel': 'Red Hazardous Bin',
    },
    'General': {
      'icon': Icons.delete_outline,
      'color': Color(0xFF6B7280),
      'bgColor': Color(0xFFF9FAFB),
      'description': 'This is general non-recyclable waste. Place it in the black bin.',
      'points': 2,
      'binLabel': 'Black General Waste Bin',
    },
  };

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _showResult = false;
          _classifiedCategory = null;
          _itemName = null;
          _confidence = null;
        });
        _classifyImage();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _classifyImage() async {
    if (_image == null) return;
    
    setState(() => _isClassifying = true);

    try {
      // Use NVIDIA Vision API for classification
      final result = await NvidiaVisionService.classifyImage(_image!);

      if (mounted) {
        setState(() {
          _classifiedCategory = result['category'];
          _itemName = result['itemName'];
          _binColor = result['binColor'];
          _disposalTip = result['disposalTip'];
          _confidence = result['confidence'];
          _isClassifying = false;
          _showResult = true;
        });
      }
    } catch (e) {
      debugPrint('Classification error: $e');
      if (mounted) {
        setState(() {
          _classifiedCategory = 'General';
          _itemName = 'Unknown item';
          _confidence = 0.5;
          _isClassifying = false;
          _showResult = true;
        });
      }
    }
  }

  bool get _isRecyclable {
    return _classifiedCategory == 'Recyclable' ||
        _classifiedCategory == 'Organic' ||
        _classifiedCategory == 'E-Waste' ||
        _classifiedCategory == 'General';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        title: const Text('Classify Waste'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_image == null) ...[
              _buildPickImageSection(),
            ] else ...[
              _buildImagePreview(),
              const SizedBox(height: 20),
              if (_isClassifying) _buildClassifyingIndicator(),
              if (_showResult) _buildClassificationResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Take a photo of the waste item',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Our AI will classify it and tell you the correct bin to use.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Powered by ZOU Vision AI - Fast, accurate waste classification',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildImageSourceCard(
          icon: Icons.camera_alt,
          title: 'Take Photo',
          subtitle: 'Use your camera to capture the item',
          onTap: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(height: 16),
        _buildImageSourceCard(
          icon: Icons.photo_library,
          title: 'Choose from Gallery',
          subtitle: 'Select an existing photo',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildImageSourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF0D9488), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 250,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.file(
              _image!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _image = null;
                    _showResult = false;
                    _classifiedCategory = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassifyingIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF0D9488)),
          const SizedBox(height: 16),
          const Text(
            'AI is analyzing your image...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Using Vision Model',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationResult() {
    if (_classifiedCategory == null) return const SizedBox.shrink();

    final info = _categoryInfo[_classifiedCategory!]!;
    final isRecyclable = _isRecyclable;

    return Column(
      children: [
        // Result card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: info['bgColor'] as Color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (info['color'] as Color).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (info['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  info['icon'] as IconData,
                  color: info['color'] as Color,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _classifiedCategory!,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: info['color'] as Color,
                ),
              ),
              if (_itemName != null) ...[
                const SizedBox(height: 4),
                Text(
                  _itemName!,
                  style: TextStyle(
                    fontSize: 16,
                    color: (info['color'] as Color).withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (_confidence != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_confidence! * 100).toInt()}% confidence',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: info['color'] as Color,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                _disposalTip ?? info['description'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (info['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${info['points']} pts available',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: info['color'] as Color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bin info card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getBinColor(_binColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete,
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
                      'Dispose in:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      info['binLabel'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Action buttons
        if (isRecyclable) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BinMapScreen(
                      category: _classifiedCategory!,
                      onValidated: () {
                        // After validation, navigate to QR scanner
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QRScannerScreen(
                              expectedCategory: _classifiedCategory!,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.location_on, color: Colors.white),
              label: Text(
                _classifiedCategory == 'General' ? 'Find Black Bin & Earn 2 Pts' : 'Find Nearest Bin & Earn Points',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _image = null;
                _showResult = false;
                _classifiedCategory = null;
              });
            },
            child: const Text(
              'Classify Another Item',
              style: TextStyle(
                color: Color(0xFF0D9488),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hazardous waste items cannot be disposed in regular campus bins. Please take to a designated safety disposal facility.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _image = null;
                  _showResult = false;
                  _classifiedCategory = null;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
                side: const BorderSide(color: Color(0xFF0D9488)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Classify Another Item',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getBinColor(String? binColor) {
    switch (binColor?.toLowerCase()) {
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'green':
        return const Color(0xFF10B981);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'red':
        return const Color(0xFFEF4444);
      case 'black':
        return const Color(0xFF374151);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
