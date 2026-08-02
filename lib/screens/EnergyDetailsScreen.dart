import 'package:deep_waste/database_manager.dart';
import 'package:flutter/material.dart';

class EnergyDetailsScreen extends StatefulWidget {
  static const String routeName = '/energy_details';

  const EnergyDetailsScreen({Key? key}) : super(key: key);

  @override
  State<EnergyDetailsScreen> createState() => _EnergyDetailsScreenState();
}

class _EnergyDetailsScreenState extends State<EnergyDetailsScreen> {
  bool _isLoading = true;
  int _totalDisposals = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final total = await DatabaseManager.instance.getTotalDisposals();
      setState(() {
        _totalDisposals = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Energy details error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final energySavedKwh = (_totalDisposals * 1.15).toStringAsFixed(1);
    final peakReductionKw = (_totalDisposals * 0.4).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Conservation Breakdown'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
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
                        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
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
                              'TOTAL ENERGY SAVED',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$energySavedKwh kWh',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Equivalent to powering ZOU Computer Lab for ${(double.parse(energySavedKwh) / 2.5).toStringAsFixed(0)} hours.',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Campus Energy Efficiency Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(Icons.power, 'Peak Power Load Reduced', '$peakReductionKw kW'),
                        const Divider(height: 24),
                        _buildStatRow(Icons.lightbulb_outline, 'Hostel Unplug Quests', '${_totalDisposals * 2} Logged'),
                        const Divider(height: 24),
                        _buildStatRow(Icons.solar_power_outlined, 'ZOU Solar Generation Boost', '18% Active Contribution'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF59E0B), size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
        ),
      ],
    );
  }
}
