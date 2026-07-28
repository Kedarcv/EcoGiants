import 'package:deep_waste/constants/size_config.dart';
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

  final List<String> _categories = ['Recyclable', 'Organic', 'E-Waste', 'General', 'Hazardous'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (_filterCategory != null) {
        _records = await DatabaseManager.instance.getDisposalsByCategory(_filterCategory!);
      } else {
        _records = await DatabaseManager.instance.getDisposals(limit: 100);
      }

      _categoryBreakdown = await DatabaseManager.instance.getCategoryBreakdown();

      setState(() => _isLoading = false);
    } catch (e) {
      print("Error loading disposal history: $e");
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
        return Colors.blue;
      case 'organic':
        return Colors.green;
      case 'e-waste':
        return Colors.purple;
      case 'general':
        return Colors.grey;
      case 'hazardous':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'e-waste':
        return Icons.devices;
      case 'general':
        return Icons.delete;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disposal History'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
      backgroundColor: const Color(0xfff5f5f5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Category breakdown chips
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(16),
                      vertical: getProportionateScreenHeight(12),
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
                              selectedColor: _getCategoryColor(cat).withOpacity(0.2),
                              checkmarkColor: _getCategoryColor(cat),
                              labelStyle: TextStyle(
                                color: isSelected ? _getCategoryColor(cat) : Colors.grey[700],
                                fontSize: getProportionateScreenWidth(13),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Stats summary
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: getProportionateScreenWidth(16),
                    ),
                    child: Row(
                      children: [
                        _buildStatCard(
                          'Total Items',
                          '${_records.length}',
                          Icons.inventory_2,
                          Colors.teal,
                        ),
                        SizedBox(width: getProportionateScreenWidth(12)),
                        _buildStatCard(
                          'Total Points',
                          '${_records.fold(0, (sum, r) => sum + r.pointsAwarded)}',
                          Icons.stars,
                          Colors.amber,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: getProportionateScreenHeight(16)),

                  // History list
                  Expanded(
                    child: _records.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: getProportionateScreenWidth(64),
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: getProportionateScreenHeight(16)),
                                Text(
                                  'No disposals yet',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(18),
                                    color: Colors.grey[500],
                                  ),
                                ),
                                SizedBox(height: getProportionateScreenHeight(8)),
                                Text(
                                  'Start disposing waste to see your history!',
                                  style: TextStyle(
                                    fontSize: getProportionateScreenWidth(14),
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _records.length,
                            padding: EdgeInsets.symmetric(
                              horizontal: getProportionateScreenWidth(16),
                            ),
                            itemBuilder: (context, index) {
                              final record = _records[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(record.category).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(record.category),
                                      color: _getCategoryColor(record.category),
                                    ),
                                  ),
                                  title: Text(
                                    record.category,
                                    style: TextStyle(
                                      fontSize: getProportionateScreenWidth(16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatDate(record.timestamp),
                                        style: TextStyle(
                                          fontSize: getProportionateScreenWidth(12),
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                      if (record.binName != null)
                                        Text(
                                          'Bin: ${record.binName}',
                                          style: TextStyle(
                                            fontSize: getProportionateScreenWidth(12),
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '+${record.pointsAwarded}',
                                      style: TextStyle(
                                        fontSize: getProportionateScreenWidth(14),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            SizedBox(width: getProportionateScreenWidth(12)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(12),
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: getProportionateScreenWidth(20),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
