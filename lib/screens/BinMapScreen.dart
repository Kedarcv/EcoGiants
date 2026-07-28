import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:deep_waste/screens/BinValidationScreen.dart';
import 'package:deep_waste/config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class BinMapScreen extends StatefulWidget {
  final String category;
  final VoidCallback? onValidated;

  const BinMapScreen({
    Key? key,
    required this.category,
    this.onValidated,
  }) : super(key: key);

  @override
  State<BinMapScreen> createState() => _BinMapScreenState();
}

class _BinMapScreenState extends State<BinMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _nearbyBins = [];
  Map<String, dynamic>? _selectedBin;

  // Mapbox access token for tile layer
  static const String _mapboxToken = AppConfig.mapboxToken;

  // Simulated bin locations around Harare, Zimbabwe
  final List<Map<String, dynamic>> _allBins = [
    {
      'id': 'bin1',
      'name': 'ZOU Campus Recycling Point',
      'lat': -17.8292,
      'lng': 31.0522,
      'categories': ['Recyclable', 'General'],
      'address': 'Harare Campus, Main Entrance',
    },
    {
      'id': 'bin2',
      'name': 'Avondale Shopping Centre',
      'lat': -17.8167,
      'lng': 31.0500,
      'categories': ['Recyclable', 'Organic', 'General'],
      'address': 'Avondale, Harare',
    },
    {
      'id': 'bin3',
      'name': 'Eastgate Mall Eco Point',
      'lat': -17.8350,
      'lng': 31.0550,
      'categories': ['Recyclable', 'E-Waste', 'General'],
      'address': 'Eastgate Mall, Samora Machel Ave',
    },
    {
      'id': 'bin4',
      'name': 'Harare City Council Depot',
      'lat': -17.8280,
      'lng': 31.0410,
      'categories': ['Hazardous', 'E-Waste', 'Recyclable'],
      'address': 'City Centre, Harare',
    },
    {
      'id': 'bin5',
      'name': 'Borrowdale Village',
      'lat': -17.7833,
      'lng': 31.0333,
      'categories': ['Recyclable', 'Organic', 'General'],
      'address': 'Borrowdale, Harare',
    },
    {
      'id': 'bin6',
      'name': 'Msasa Industrial Area',
      'lat': -17.8100,
      'lng': 31.0800,
      'categories': ['E-Waste', 'Hazardous', 'General'],
      'address': 'Msasa, Harare',
    },
    {
      'id': 'bin7',
      'name': 'Chitungwiza Civic Centre',
      'lat': -17.9917,
      'lng': 31.0500,
      'categories': ['Recyclable', 'Organic', 'General'],
      'address': 'Chitungwiza',
    },
    {
      'id': 'bin8',
      'name': 'Epworth Recycling Hub',
      'lat': -17.8833,
      'lng': 31.1333,
      'categories': ['Recyclable', 'Organic', 'E-Waste'],
      'address': 'Epworth, Harare',
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission permanently denied. Please enable in settings.';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _nearbyBins = _getNearbyBins(position);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Use default Harare location
      setState(() {
        _currentPosition = Position(
          latitude: -17.8292,
          longitude: 31.0522,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        _nearbyBins = _getNearbyBins(_currentPosition!);
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getNearbyBins(Position position) {
    final filteredBins = _allBins.where((bin) {
      final categories = bin['categories'] as List<String>;
      return categories.contains(widget.category);
    }).toList();

    for (var bin in filteredBins) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        bin['lat'],
        bin['lng'],
      );
      bin['distance'] = distance;
    }

    filteredBins.sort((a, b) => a['distance'].compareTo(b['distance']));

    return filteredBins.take(5).toList();
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.round()}m away';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km away';
    }
  }

  Color _getBinColor(String category) {
    switch (category) {
      case 'Recyclable': return const Color(0xFF3B82F6);
      case 'Organic': return const Color(0xFF10B981);
      case 'E-Waste': return const Color(0xFF8B5CF6);
      case 'Hazardous': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        title: Text('Nearby ${widget.category} Bins'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0D9488)),
                  SizedBox(height: 16),
                  Text('Finding nearby bins...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _getCurrentLocation();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                          ),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _currentPosition?.latitude ?? -17.8292,
                          _currentPosition?.longitude ?? 31.0522,
                        ),
                        initialZoom: 14,
                        onTap: (tapPosition, point) {
                          setState(() => _selectedBin = null);
                        },
                      ),
                      children: [
                        // Tile layer with Mapbox
                        TileLayer(
                          urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$_mapboxToken',
                          userAgentPackageName: 'com.ecogiants.zou.app',
                        ),
                        // Current location marker
                        if (_currentPosition != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        // Bin markers
                        MarkerLayer(
                          markers: _nearbyBins.map((bin) {
                            final isSelected = _selectedBin?['id'] == bin['id'];
                            return Marker(
                              point: LatLng(bin['lat'], bin['lng']),
                              width: isSelected ? 50 : 40,
                              height: isSelected ? 50 : 40,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _selectedBin = bin);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getBinColor(widget.category),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isSelected ? 4 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    // Bottom sheet with bin list
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildBinListSheet(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildBinListSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _getBinColor(widget.category),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_nearbyBins.length} ${widget.category} bins nearby',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _nearbyBins.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No ${widget.category} bins found nearby',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _nearbyBins.length,
                    itemBuilder: (context, index) {
                      final bin = _nearbyBins[index];
                      return _buildBinCard(bin);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinCard(Map<String, dynamic> bin) {
    final isSelected = _selectedBin?['id'] == bin['id'];
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedBin = bin);
        _mapController.move(
          LatLng(bin['lat'], bin['lng']),
          16,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _getBinColor(widget.category).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _getBinColor(widget.category) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getBinColor(widget.category),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bin['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bin['address'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBinColor(widget.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDistance(bin['distance']),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getBinColor(widget.category),
                    ),
                  ),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final lat = bin['lat'];
                        final lng = bin['lng'];
                        final url = Uri.parse(
                          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Directions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: const BorderSide(color: Color(0xFF0D9488)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BinValidationScreen(
                              category: widget.category,
                              binName: bin['name'],
                            ),
                          ),
                        ).then((_) {
                          Navigator.pop(context);
                          widget.onValidated?.call();
                        });
                      },
                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      label: const Text(
                        'Validate',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
