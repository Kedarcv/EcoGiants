import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/water_leak_report.dart';
import 'package:deep_waste/screens/EnergyDetailsScreen.dart';
import 'package:deep_waste/screens/WasteDetailsScreen.dart';
import 'package:deep_waste/screens/WaterDetailsScreen.dart';
import 'package:deep_waste/screens/WaterLeakReportScreen.dart';
import 'package:flutter/material.dart';

class SustainabilityAnalyticsScreen extends StatefulWidget {
  static const String routeName = '/sustainability_analytics';

  const SustainabilityAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<SustainabilityAnalyticsScreen> createState() =>
      _SustainabilityAnalyticsScreenState();
}

class _SustainabilityAnalyticsScreenState
    extends State<SustainabilityAnalyticsScreen> {
  bool _isLoading = true;
  int _totalDisposals = 0;
  int _totalPoints = 0;
  Map<String, int> _breakdown = {};
  List<WaterLeakReport> _leaks = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final totalItems = await DatabaseManager.instance.getTotalDisposals();
      final breakdownMap =
          await DatabaseManager.instance.getCategoryBreakdown();
      final records = await DatabaseManager.instance.getDisposals();
      final leakReports = await DatabaseManager.instance.getWaterLeaks();

      int points = 0;
      for (final r in records) {
        points += r.pointsAwarded;
      }

      setState(() {
        _totalDisposals = totalItems;
        _totalPoints = points;
        _breakdown = breakdownMap;
        _leaks = leakReports;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final co2SavedKg = (_totalDisposals * 0.42).toStringAsFixed(1);
    final energySavedKwh = (_totalDisposals * 1.15).toStringAsFixed(1);
    final waterSavedLiters = (_totalDisposals * 3.8).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ZOU Sustainability Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF16A34A)),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF16A34A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'REALTIME DATA DASHBOARD',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              const Icon(Icons.insights,
                                  color: Colors.white, size: 22),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ZOU Campus Carbon Impact (${_totalPoints} Pts Generated)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Data-driven environmental monitoring for ZOU Green Innovation Challenge 2026.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Environmental Impact Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Tap cards for details →',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3 Clickable Metric Stat Cards
                    Row(
                      children: [
                        _buildMetricCard(
                          icon: Icons.co2_rounded,
                          label: 'CO₂ Avoided',
                          value: '$co2SavedKg kg',
                          color: const Color(0xFF10B981),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WasteDetailsScreen(),
                              ),
                            );
                            _loadAnalytics();
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          icon: Icons.bolt_rounded,
                          label: 'Energy Saved',
                          value: '$energySavedKwh kWh',
                          color: const Color(0xFFF59E0B),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EnergyDetailsScreen(),
                              ),
                            );
                            _loadAnalytics();
                          },
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          icon: Icons.water_drop_rounded,
                          label: 'Water Saved',
                          value: '$waterSavedLiters L',
                          color: const Color(0xFF3B82F6),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WaterDetailsScreen(),
                              ),
                            );
                            _loadAnalytics();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Water Leaks Summary & Reporter Link
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.water_drop,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Campus Water Leaks (${_leaks.length} Reported)',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Scan GPS pin & submit photos of broken taps.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WaterLeakReportScreen(),
                                ),
                              );
                              if (res == true) _loadAnalytics();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0284C7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: const Text(
                              '+ Report',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Clickable Waste Diversion Breakdown Card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WasteDetailsScreen(),
                          ),
                        );
                      },
                      child: Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ZOU Waste Diversion Breakdown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    color: Colors.grey.shade500),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildProgressBar(
                                'Recyclable (Paper, Plastic, Metal)',
                                _breakdown['Recyclable'] ?? 0,
                                _totalDisposals,
                                const Color(0xFF3B82F6)),
                            const SizedBox(height: 14),
                            _buildProgressBar(
                                'Organic (Food & Garden)',
                                _breakdown['Organic'] ?? 0,
                                _totalDisposals,
                                const Color(0xFF10B981)),
                            const SizedBox(height: 14),
                            _buildProgressBar(
                                'E-Waste (Electronics & Batteries)',
                                _breakdown['E-Waste'] ?? 0,
                                _totalDisposals,
                                const Color(0xFF8B5CF6)),
                            const SizedBox(height: 14),
                            _buildProgressBar(
                                'General & Landfill Trash',
                                _breakdown['General'] ?? 0,
                                _totalDisposals,
                                Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Smart Campus Bin Fill & Optimization',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Predictive Bin Route Card
                    Container(
                      padding: const EdgeInsets.all(18),
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
                          _buildBinStatusRow(
                              'ZOU Main Campus — Green Hub 1', 65, 'Optimal'),
                          const Divider(height: 20),
                          _buildBinStatusRow(
                              'ZOU Library Node — Blue Bin', 88, 'Pickup Needed'),
                          const Divider(height: 20),
                          _buildBinStatusRow(
                              'Bulawayo Regional Hub — Bin B', 30, 'Normal'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // UN SDG Compliance Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.public,
                              color: Color(0xFFD97706), size: 28),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'UN SDG 11, 12 & 13 Compliance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Eco-Giants supports Sustainable Cities, Responsible Consumption & Climate Action at ZOU.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF78350F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 12, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      String label, int count, int total, Color color) {
    final pct = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$count items (${(pct * 100).toInt()}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBinStatusRow(String name, int pct, String status) {
    final isFull = pct >= 80;

    return Row(
      children: [
        Icon(
          isFull ? Icons.warning_amber_rounded : Icons.delete_outline_rounded,
          color: isFull ? Colors.red : Colors.teal,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Capacity: $pct% • Status: $status',
                style: TextStyle(
                  fontSize: 12,
                  color: isFull ? Colors.red : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isFull
                ? Colors.red.shade100
                : const Color(0xFF10B981).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$pct%',
            style: TextStyle(
              color: isFull ? Colors.red.shade800 : const Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
