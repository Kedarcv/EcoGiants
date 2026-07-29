import 'dart:io';
import 'package:deep_waste/database_manager.dart';
import 'package:deep_waste/models/disposal_record.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DisposalHistoryScreen extends StatefulWidget {
  static String routeName = "/disposal_history";

  const DisposalHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DisposalHistoryScreen> createState() => _DisposalHistoryScreenState();
}

class _DisposalHistoryScreenState extends State<DisposalHistoryScreen> {
  List<DisposalRecord> _records = [];
  bool _isLoading = true;
  String? _filterCategory;
  Map<String, int> _categoryBreakdown = {};

  final List<String> _categories = [
    'Recyclable',
    'Organic',
    'E-Waste',
    'General',
    'Hazardous'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (_filterCategory != null) {
        _records =
            await DatabaseManager.instance.getDisposalsByCategory(_filterCategory!);
      } else {
        _records = await DatabaseManager.instance.getDisposals(limit: 100);
      }

      _categoryBreakdown =
          await DatabaseManager.instance.getCategoryBreakdown();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error loading disposal history: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (_) {
      return timestamp;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
      case 'plastic':
      case 'glass':
      case 'paper':
      case 'cardboard':
        return Colors.blue;
      case 'organic':
        return Colors.green;
      case 'e-waste':
        return Colors.purple;
      case 'general':
      case 'trash':
        return Colors.grey.shade700;
      case 'hazardous':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
      case 'plastic':
      case 'glass':
      case 'paper':
      case 'cardboard':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'e-waste':
        return Icons.devices;
      case 'general':
      case 'trash':
        return Icons.delete;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.delete_outline;
    }
  }

  String _getCategoryImage(String category) {
    switch (category.toLowerCase()) {
      case 'plastic':
        return 'assets/images/plastic.png';
      case 'glass':
        return 'assets/images/glass.png';
      case 'paper':
        return 'assets/images/paper.png';
      case 'cardboard':
        return 'assets/images/cardboard.png';
      case 'metal':
        return 'assets/images/metal.png';
      case 'organic':
        return 'assets/images/background.png';
      case 'general':
      case 'trash':
        return 'assets/images/trash.png';
      default:
        return 'assets/images/plastic.png';
    }
  }

  void _showRecordDetailsModal(DisposalRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final categoryColor = _getCategoryColor(record.category);
        final assetImg = _getCategoryImage(record.category);

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Image Header
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: record.imagePath != null &&
                          File(record.imagePath!).existsSync()
                      ? Image.file(
                          File(record.imagePath!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          assetImg,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 140,
                            color: categoryColor.withOpacity(0.1),
                            child: Icon(
                              _getCategoryIcon(record.category),
                              size: 64,
                              color: categoryColor,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Category & Points Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(_getCategoryIcon(record.category),
                              color: categoryColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            record.category,
                            style: TextStyle(
                              color: categoryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${record.pointsAwarded} Pts Earned',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 12),

                // Details Grid
                _buildDetailRow(
                  Icons.calendar_today_rounded,
                  'Disposal Date',
                  _formatDate(record.timestamp),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.delete_sweep_rounded,
                  'Target Bin',
                  record.binName ?? 'ZOU Campus Green Bin',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.qr_code_scanner_rounded,
                  'QR Verification ID',
                  record.qrCode ?? 'ZOU-BIN-RECY-042',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.location_on_rounded,
                  'Campus Location',
                  'ZOU Open Campus — Green Hub Node 3',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.eco_rounded,
                  'ECO Impact',
                  'Saved approx. 0.35 kg CO₂ emissions',
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Close Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Disposal History'),
        elevation: 0,
        actions: [
          if (_filterCategory != null)
            TextButton(
              onPressed: () {
                setState(() => _filterCategory = null);
                _loadData();
              },
              child: const Text('Clear Filter'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Category breakdown chips
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          final count = _categoryBreakdown[cat] ?? 0;
                          final isSelected = _filterCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('$cat ($count)'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _filterCategory = selected ? cat : null;
                                });
                                _loadData();
                              },
                              selectedColor:
                                  _getCategoryColor(cat).withOpacity(0.2),
                              checkmarkColor: _getCategoryColor(cat),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? _getCategoryColor(cat)
                                    : Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Stats summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildStatCard(
                          'Total Items',
                          '${_records.length}',
                          Icons.inventory_2,
                          Colors.teal,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          'Total Points',
                          '${_records.fold(0, (sum, r) => sum + r.pointsAwarded)}',
                          Icons.stars,
                          Colors.amber,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // History list
                  Expanded(
                    child: _records.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No disposals yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start disposing waste to see your history!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _records.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemBuilder: (context, index) {
                              final record = _records[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  onTap: () => _showRecordDetailsModal(record),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(record.category)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(record.category),
                                      color:
                                          _getCategoryColor(record.category),
                                    ),
                                  ),
                                  title: Text(
                                    record.category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDate(record.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      if (record.binName != null)
                                        Text(
                                          'Bin: ${record.binName}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '+${record.pointsAwarded}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
