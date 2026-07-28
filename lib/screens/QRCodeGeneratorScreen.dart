import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:deep_waste/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeGeneratorScreen extends StatefulWidget {
  static const String routeName = '/qr_generator';

  const QRCodeGeneratorScreen({super.key});

  @override
  State<QRCodeGeneratorScreen> createState() => _QRCodeGeneratorScreenState();
}

class _QRCodeGeneratorScreenState extends State<QRCodeGeneratorScreen> {
  static const Map<String, String> _categoryCodes = {
    'Recyclable': 'REC',
    'Organic': 'ORG',
    'E-Waste': 'EWA',
    'General': 'GEN',
    'Hazardous': 'HAZ',
  };

  String _selectedCategory = 'Recyclable';
  final _binIdController = TextEditingController();
  String? _generatedQRData;
  int _qrCount = 1;

  @override
  void dispose() {
    _binIdController.dispose();
    super.dispose();
  }

  String _generateQRData(String category, String binId) {
    final code = _categoryCodes[category] ?? 'GEN';
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final raw = 'EG_${binId}_${code}_$timestamp';
    final checksum = sha256.convert(utf8.encode(raw)).toString().substring(0, 6).toUpperCase();
    return '${raw}_$checksum';
  }

  void _generate() {
    final binId = _binIdController.text.trim();
    if (binId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Bin ID')),
      );
      return;
    }
    setState(() {
      _generatedQRData = _generateQRData(_selectedCategory, binId);
    });
  }

  void _generateMultiple() {
    final baseId = _binIdController.text.trim();
    if (baseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a base Bin ID')),
      );
      return;
    }
    setState(() {
      _generatedQRData = _generateQRData(_selectedCategory, '${baseId}_${_qrCount}');
      _qrCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Generate Test QR Codes'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category selector
            const Text(
              'Bin Category',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF1E293B),
              items: _categoryCodes.keys.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 24),

            // Bin ID input
            const Text(
              'Bin ID',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _binIdController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(hint: 'e.g. BIN001'),
            ),

            const SizedBox(height: 32),

            // Generate buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.qr_code, size: 20),
                    label: const Text('Generate QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generateMultiple,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Generate Batch'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D9488),
                      side: const BorderSide(color: Color(0xFF0D9488)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Generated QR code
            if (_generatedQRData != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _generatedQRData!,
                      version: QrVersions.auto,
                      size: 220,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F172A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _generatedQRData!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Format: EG_BinID_CATEGORY_TIMESTAMP_CHECKSUM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _generatedQRData!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('QR data copied!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy Data'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0D9488),
                              side: const BorderSide(color: Color(0xFF0D9488)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Take a screenshot to save'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.save_alt, size: 18),
                            label: const Text('Screenshot'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
