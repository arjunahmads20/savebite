import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../theme/app_theme.dart';
import '../screens/account/account_screen.dart';
import '../providers/auth_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class TopNavBar extends StatefulWidget implements PreferredSizeWidget {
  final String location; // Fallback location

  const TopNavBar({super.key, required this.location});

  @override
  State<TopNavBar> createState() => _TopNavBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _TopNavBarState extends State<TopNavBar> {
  String? _currentLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
          
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
          
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          String location = '${place.locality ?? place.subAdministrativeArea}, ${place.country}';     
          setState(() {
            _currentLocation = location.length > 18 
                ? '${location.substring(0, 18)}...' 
                : location;
          });
        }
      }
    } catch (e) {
      // Fallback to default
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final userName = user?['first_name']?.isNotEmpty == true 
        ? user!['first_name'] 
        : (user?['username'] ?? 'User');

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'your_location'.tr(),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 16, color: AppTheme.primaryYellow),
              const SizedBox(width: 4),
              Text(
                _currentLocation ?? widget.location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.textPrimary),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
            child: Row(
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: const Icon(LucideIcons.user, color: AppTheme.primaryGreen),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

