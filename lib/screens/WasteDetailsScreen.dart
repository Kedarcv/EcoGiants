import 'package:deep_waste/database_manager.dart';
import 'package:flutter/material.dart';

class WasteDetailsScreen extends StatefulWidget {
  static const String routeName = '/waste_details';

  const WasteDetailsScreen({Key? key}) : super(key: key);

  @override
  State<WasteDetailsScreen> createState() => _WasteDetailsScreenState();
}

class _WasteDetailsScreenState extends State<WasteDetailsScreen> {
  bool _isLoading = true;
  int _totalDisposals = 0;
  Map<String, int> _breakdown = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final total = await DatabaseManager.instance.getTotalDisposals();
      final map = await DatabaseManager.instance.getCategoryBreakdown();
      setState(() {
        _totalDisposals = total;
        _breakdown = map;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Waste details error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final co2SavedKg = (_totalDisposals * 0.42).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CO₂ Carbon & Waste Details'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL CO₂ AVOIDED',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Icon(Icons.co2_rounded, color: Colors.white, size: 28),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$co2SavedKg kg CO₂',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Equivalent to planting ${(double.parse(co2SavedKg) * 0.12).toStringAsFixed(1)} mature trees at ZOU Harare Campus.',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Categorized Landfill Diversion',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildCategoryRow('Recyclables (Metal & Plastic)', _breakdown['Recyclable'] ?? 0, Colors.blue),
                        const Divider(height: 24),
                        _buildCategoryRow('Organic Waste (Composting)', _breakdown['Organic'] ?? 0, Colors.green),
                        const Divider(height: 24),
                        _buildCategoryRow('E-Waste & Batteries', _breakdown['E-Waste'] ?? 0, Colors.purple),
                        const Divider(height: 24),
                        _buildCategoryRow('General Waste', _breakdown['General'] ?? 0, Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryRow(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '$count items',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
