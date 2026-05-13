import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_keys.dart';
import '../../theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;

  // Default to Jakarta, Indonesia
  late LatLng _selectedPosition;
  String _address = '';
  bool _isGeocoding = false;
  bool _isConfirmable = false;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition ?? const LatLng(-6.2088, 106.8456);
  }

  Future<void> _onMapTap(LatLng pos) async {
    setState(() {
      _selectedPosition = pos;
      _isGeocoding = true;
      _isConfirmable = false;
    });
    final address = await _reverseGeocode(pos.latitude, pos.longitude);
    if (!mounted) return;
    setState(() {
      _address = address;
      _isGeocoding = false;
      _isConfirmable = address.isNotEmpty;
    });
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng&key=${ApiKeys.googleMaps}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['formatted_address'] as String? ?? '$lat, $lng';
        }
      }
    } catch (_) {}
    return '$lat, $lng'; // Fallback to raw coordinates
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('pick_location').tr(),
        actions: [
          TextButton.icon(
            onPressed: _isConfirmable
                ? () => Navigator.pop(context, _address)
                : null,
            icon: Icon(
              Icons.check_circle,
              color: _isConfirmable ? AppTheme.primaryGreen : Colors.grey,
            ),
            label: Text(
              'Confirm',
              style: TextStyle(
                color: _isConfirmable ? AppTheme.primaryGreen : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 14,
            ),
            onMapCreated: (c) => _mapController = c,
            onTap: _onMapTap,
            markers: {
              if (_isConfirmable || _address.isNotEmpty)
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selectedPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),

          // Top hint banner
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: AppTheme.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tap anywhere on the map to set pick-up location',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Geocoding spinner overlay
          if (_isGeocoding)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Getting address…', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // Address card at bottom
          if (_address.isNotEmpty && !_isGeocoding)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            _address,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
