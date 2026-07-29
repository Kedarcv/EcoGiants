import 'package:deep_waste/constants/size_config.dart';
import 'package:deep_waste/screens/QRScannerScreen.dart';
import 'package:flutter/material.dart';

class BinValidationScreen extends StatefulWidget {
  final String category;
  final String binName;

  const BinValidationScreen({
    Key? key,
    required this.category,
    this.binName = '',
  }) : super(key: key);

  @override
  State<BinValidationScreen> createState() => _BinValidationScreenState();
}

class _BinValidationScreenState extends State<BinValidationScreen> {
  late String _selectedCategory;

  final List<Map<String, dynamic>> _binTypes = [
    {
      'name': 'Recyclable',
      'label': 'Recyclable Bin',
      'subtitle': 'Plastic, Paper, Metal, Glass',
      'points': 30,
      'color': const Color(0xFF0D9488),
      'icon': Icons.recycling,
      'badge': '30 Points',
    },
    {
      'name': 'Organic',
      'label': 'Organic Waste Bin',
      'subtitle': 'Food scraps, Garden waste, Compost',
      'points': 20,
      'color': const Color(0xFF16A34A),
      'icon': Icons.eco,
      'badge': '20 Points',
    },
    {
      'name': 'E-Waste',
      'label': 'E-Waste Bin',
      'subtitle': 'Electronics, Batteries, Chargers, Cables',
      'points': 40,
      'color': const Color(0xFF2563EB),
      'icon': Icons.devices,
      'badge': '40 Points',
    },
    {
      'name': 'Hazardous',
      'label': 'Hazardous Bin',
      'subtitle': 'Chemicals, Aerosols, Medical items',
      'points': 50,
      'color': const Color(0xFFDC2626),
      'icon': Icons.warning_amber_rounded,
      'badge': '50 Points',
    },
    {
      'name': 'General',
      'label': 'General Waste (Black Bin)',
      'subtitle': 'Non-recyclable trash, Wrappers, Mixed waste',
      'points': 2,
      'color': const Color(0xFF334155),
      'icon': Icons.delete_outline,
      'badge': '2 Points',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select category passed to widget or default to Recyclable
    final matched = _binTypes.firstWhere(
      (b) => b['name'].toString().toLowerCase() == widget.category.toLowerCase(),
      orElse: () => _binTypes.first,
    );
    _selectedCategory = matched['name'];
  }

  void _proceedToQrScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          expectedCategory: _selectedCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Select Bin Type',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Which bin are you standing at?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select the bin category to proceed to QR code scanning and earn points.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _binTypes.length,
                itemBuilder: (context, index) {
                  final bin = _binTypes[index];
                  final isSelected = _selectedCategory == bin['name'];
                  final Color color = bin['color'];

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = bin['name'];
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade200,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? color.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.03),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                bin['icon'] as IconData,
                                color: color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bin['label'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '+${bin['points']} pts',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bin['subtitle'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Radio<String>(
                              value: bin['name'],
                              groupValue: _selectedCategory,
                              activeColor: color,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _proceedToQrScan,
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  label: const Text(
                    'Proceed to QR Scan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
