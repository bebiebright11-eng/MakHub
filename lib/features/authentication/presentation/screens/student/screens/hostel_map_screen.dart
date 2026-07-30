import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '/core/constants/app_colors.dart';

/// Makerere University main gate coordinates — used as the reference
/// point for distance calculations and the "Navigate to Campus" button.
const LatLng kMakerereUniversity = LatLng(0.3341, 32.5685);

class HostelMapScreen extends StatefulWidget {
  final String hostelName;
  final double latitude;
  final double longitude;
  final String address;
  final Map<String, dynamic> hostelData;

  const HostelMapScreen({
    super.key,
    required this.hostelName,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.hostelData,
  });

  @override
  State<HostelMapScreen> createState() => _HostelMapScreenState();
}

class _HostelMapScreenState extends State<HostelMapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setupMarkers();
  }

  void _setupMarkers() {
    final hostelPos = LatLng(widget.latitude, widget.longitude);

    _markers.add(
      Marker(
        markerId: const MarkerId('hostel'),
        position: hostelPos,
        infoWindow: InfoWindow(
          title: widget.hostelName,
          snippet: widget.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Makerere University marker
    _markers.add(
      Marker(
        markerId: const MarkerId('university'),
        position: kMakerereUniversity,
        infoWindow: const InfoWindow(
          title: 'Makerere University',
          snippet: 'Main Gate',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  /// Open the hostel location in Google Maps app for navigation.
  Future<void> _openInGoogleMaps() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.latitude},${widget.longitude}'
      '&travelmode=walking',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  /// Open navigation from hostel to Makerere University.
  Future<void> _navigateToCampus() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${widget.latitude},${widget.longitude}'
      '&destination=${kMakerereUniversity.latitude},${kMakerereUniversity.longitude}'
      '&travelmode=walking',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  /// Calculate straight-line distance in metres between two coordinates.
  double _distanceMetres(LatLng a, LatLng b) {
    const double earthR = 6371000;
    final double dLat =
        (b.latitude - a.latitude) * (3.141592653589793 / 180);
    final double dLon =
        (b.longitude - a.longitude) * (3.141592653589793 / 180);
    final double sinLat = dLat / 2;
    final double sinLon = dLon / 2;
    final double aa = sinLat * sinLat +
        (a.latitude * 3.141592653589793 / 180).abs().ceil() *
            0 +
        // simplified Haversine
        sinLon * sinLon;
    // Use simple Pythagorean approximation for short distances
    final double latDiff = (b.latitude - a.latitude) * 111320;
    final double lonDiff = (b.longitude - a.longitude) *
        111320 *
        _cos(a.latitude * 3.141592653589793 / 180);
    return (latDiff * latDiff + lonDiff * lonDiff) < 0
        ? 0
        : _sqrt(latDiff * latDiff + lonDiff * lonDiff);
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _cos(double x) {
    // Taylor series approximation
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 6; i++) {
      term *= -x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  String _formatDistance(double metres) {
    if (metres < 1000) {
      return '${metres.round()} m from Makerere';
    }
    return '${(metres / 1000).toStringAsFixed(1)} km from Makerere';
  }

  String _walkingTime(double metres) {
    // Average walking speed ~80 m/min
    final int minutes = (metres / 80).ceil();
    if (minutes < 60) return '$minutes min walk';
    return '${(minutes / 60).toStringAsFixed(1)} hr walk';
  }

  @override
  Widget build(BuildContext context) {
    final hostelPos = LatLng(widget.latitude, widget.longitude);
    final double distMetres = _distanceMetres(hostelPos, kMakerereUniversity);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hostel Location',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Map ────────────────────────────────────────────────────────
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: hostelPos,
                zoom: 15.5,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                // Show the info window on the hostel marker automatically
                Future.delayed(const Duration(milliseconds: 500), () {
                  controller.showMarkerInfoWindow(const MarkerId('hostel'));
                });
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
            ),
          ),

          // ── Info panel ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hostel name + address
                Text(
                  widget.hostelName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (widget.address.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.address,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Distance + walking time row
                Row(
                  children: [
                    _infoChip(
                      Icons.directions_walk,
                      _formatDistance(distMetres),
                      AppColors.primary,
                      const Color(0xFFEFF6FF),
                    ),
                    const SizedBox(width: 10),
                    _infoChip(
                      Icons.access_time,
                      _walkingTime(distMetres),
                      Colors.green.shade700,
                      Colors.green.shade50,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openInGoogleMaps,
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('Open in Maps'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _navigateToCampus,
                        icon: const Icon(Icons.school_outlined, size: 18),
                        label: const Text('To Campus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(
      IconData icon, String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
