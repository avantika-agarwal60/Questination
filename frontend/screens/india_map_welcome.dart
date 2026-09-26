import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class IndiaMapWelcomeScreen extends StatefulWidget {
  final VoidCallback onExplorePressed;

  const IndiaMapWelcomeScreen({super.key, required this.onExplorePressed});

  @override
  State<IndiaMapWelcomeScreen> createState() => _IndiaMapWelcomeScreenState();
}

class _IndiaMapWelcomeScreenState extends State<IndiaMapWelcomeScreen> {
  final MapController _mapController = MapController();
  final LatLng _indiaCenter = const LatLng(22.5937, 78.9629);

  final List<Map<String, dynamic>> _questPins = [
    {
      'name': 'LUCKNOW QUEST',
      'location': const LatLng(26.8467, 80.9462),
      'active': true,
    },
    {
      'name': 'DELHI QUEST',
      'location': const LatLng(28.6139, 77.2090),
      'active': false,
    },
    {
      'name': 'JAIPUR QUEST',
      'location': const LatLng(26.9124, 75.7873),
      'active': false,
    },
    {
      'name': 'MUMBAI QUEST',
      'location': const LatLng(19.0760, 72.8777),
      'active': false,
    },
    {
      'name': 'BENGALURU QUEST',
      'location': const LatLng(12.9716, 77.5946),
      'active': false,
    },
  ];

  static const List<double> _pixelMapMatrix = <double>[
    0.1,
    0.4,
    0.2,
    0,
    0,
    0.2,
    0.6,
    0.5,
    0,
    0,
    0.3,
    0.5,
    0.8,
    0,
    0,
    0.0,
    0.0,
    0.0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      body: SafeArea(
        child: Stack(
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix(_pixelMapMatrix),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _indiaCenter,
                  initialZoom: 4.8,
                  minZoom: 4.0,
                  maxZoom: 7.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.my_first_app',
                  ),
                  MarkerLayer(
                    markers: _questPins.map((pin) {
                      final bool isActive = pin['active'] as bool;
                      return Marker(
                        point: pin['location'] as LatLng,
                        width: 100,
                        height: 60,
                        child: GestureDetector(
                          onTap: () {
                            if (isActive) {
                              widget.onExplorePressed();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF1684A7),
                                  content: Text(
                                    '${pin['name']} Unlocks Soon!',
                                    style: GoogleFonts.pressStart2p(
                                      fontSize: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFFFAF179)
                                      : Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFF1684A7),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  pin['name'].toString().split(' ')[0],
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 6,
                                    color: const Color(0xFF1684A7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.location_on,
                                color: isActive
                                    ? const Color(0xFF0EA391)
                                    : Colors.grey,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F1EA).withOpacity(0.92),
                  border: Border.all(color: const Color(0xFF1684A7), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'QUESTERS',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 16,
                        color: const Color(0xFF1684A7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SELECT AN ACTIVE QUEST PIN IN INDIA',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 7,
                        color: const Color(0xFF0EA391),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA391),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF1684A7), width: 2),
                  ),
                  elevation: 6,
                ),
                onPressed:
                    widget.onExplorePressed, // Calls parent shell tab switch
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'EXPLORE QUESTS',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
