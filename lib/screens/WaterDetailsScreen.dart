import 'dart:io';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/water_leak_report.dart';
import 'package:deep_waste/screens/WaterLeakReportScreen.dart';
import 'package:flutter/material.dart';

class WaterDetailsScreen extends StatefulWidget {
  static const String routeName = '/water_details';

  const WaterDetailsScreen({Key? key}) : super(key: key);

  @override
  State<WaterDetailsScreen> createState() => _WaterDetailsScreenState();
}

class _WaterDetailsScreenState extends State<WaterDetailsScreen> {
  bool _isLoading = true;
  List<WaterLeakReport> _reports = [];
  int _totalDisposals = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final leaks = await DatabaseManager.instance.getWaterLeaks();
      final total = await DatabaseManager.instance.getTotalDisposals();
      setState(() {
        _reports = leaks;
        _totalDisposals = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading water details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waterSavedLiters = (_totalDisposals * 3.8).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Conservation & Leaks'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WaterLeakReportScreen(),
            ),
          );
          if (res == true) _loadData();
        },
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text(
          'Report Water Leak',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
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
                                'TOTAL WATER CONSERVED',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              Icon(Icons.water_drop_rounded,
                                  color: Colors.white, size: 24),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$waterSavedLiters Liters',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estimated clean water saved through campus recycling & leak prevention.',
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Active Leak Tickets Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reported Campus Water Leaks (${_reports.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_reports.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Color(0xFF10B981), size: 48),
                            SizedBox(height: 12),
                            Text(
                              'No Active Leaks Reported',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap the "+ Report Water Leak" button below to report campus water wastage!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: report.imagePath.isNotEmpty &&
                                          File(report.imagePath).existsSync()
                                      ? Image.file(
                                          File(report.imagePath),
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.blue.shade100,
                                          child: const Icon(Icons.water_drop,
                                              color: Color(0xFF0284C7)),
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              report.locationName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              report.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Severity: ${report.severity}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0284C7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        report.aiReport,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }
}
