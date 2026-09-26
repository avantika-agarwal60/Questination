// ignore_for_file: non_constant_identifier_names, strict_top_level_inference, unused_element

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:my_first_app/main.dart';

import 'quest_completion_quiz.dart'; // Import the quiz helper

class QuestMapWidget extends StatefulWidget {
  final String questName;
  final String clueText;

  const QuestMapWidget({
    super.key,
    this.questName = 'Dilkusha Kothi',
    this.clueText = 'Located near the entrance heritage plaque archway',
  });

  @override
  State<QuestMapWidget> createState() => _QuestMapWidgetState();
}

class _QuestMapWidgetState extends State<QuestMapWidget> {
  final MapController _mapController = MapController();

  // Palette Colors
  static const Color oceanBlue = Color(0xFF1684A7);
  static const Color tealGreen = Color(0xFF0EA391);
  static const Color sunnyYellow = Color(0xFFFAF179);
  static const Color backgroundOffWhite = Color(0xFFF4F4F4);

  // Default Lucknow fallback coordinates
  LatLng _userLocation = const LatLng(26.8467, 80.9462);
  LatLng _destinationLocation = const LatLng(
    26.8375,
    80.9631,
  ); // Dilkusha Kothi

  // OSRM Street Route Points
  List<LatLng> _routePoints = [];

  bool _isLoadingLocation = false;
  String _statusMessage = 'GPS Ready';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
    });
  }

  // Example: Fetching quest location dynamically from Supabase
  Future<void> _fetchQuestFromSupabase() async {
    try {
      final List<dynamic> response = await supabase
          .from('quests')
          .select('*'); // Reads rows from database

      if (response.isNotEmpty && mounted) {
        final firstQuest = response.first;

        setState(() {
          _destinationLocation = LatLng(
            (firstQuest['lat'] as num).toDouble(),
            (firstQuest['lng'] as num).toDouble(),
          );
        });
        debugPrint('Loaded destination from Supabase: $_destinationLocation');
      }
    } catch (e) {
      debugPrint('Error fetching quest: $e');
    }
  }

  // 1. Fetch OSRM Road Route Geometry
  Future<void> _fetchOSRMRoute() async {
    final String url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${_userLocation.longitude},${_userLocation.latitude};'
        '${_destinationLocation.longitude},${_destinationLocation.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];

          if (mounted) {
            setState(() {
              _routePoints = coordinates
                  .map(
                    (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
                  )
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      // Fallback to straight line if OSRM service is unreachable
      if (mounted) {
        setState(() {
          _routePoints = [_userLocation, _destinationLocation];
        });
      }
    }
  }

  // 2. Fetch Live GPS Location
  Future<void> _initLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _statusMessage = 'Checking GPS...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateStatus('GPS Disabled in Settings');
        await _fetchOSRMRoute();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _updateStatus('Permission Denied');
          await _fetchOSRMRoute();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _updateStatus('Permission Blocked');
        await _fetchOSRMRoute();
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position!.latitude, position.longitude);
          _isLoadingLocation = false;
          _statusMessage = 'GPS Active';
        });
        _mapController.move(_userLocation, 14.5);
      }
    } catch (e) {
      _updateStatus('Using Default Location');
    }

    // Update OSRM route after location resolves
    await _fetchOSRMRoute();
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundOffWhite,
      body: Stack(
        children: [
          // Interactive Map Layer with Custom Palette Filter
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14.2,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.my_first_app',
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.1, 0.5, 0.1, 0, 22, // Red Channel
                      0.3, 0.7, 0.4, 0, 130, // Green Channel
                      0.6, 0.2, 0.8, 0, 167, // Blue Channel
                      0, 0, 0, 1, 0, // Alpha
                    ]),
                    child: tileWidget,
                  );
                },
              ),

              // OSRM Street Polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints.isNotEmpty
                        ? _routePoints
                        : [_userLocation, _destinationLocation],
                    strokeWidth: 6.0,
                    color: sunnyYellow,
                  ),
                ],
              ),

              // Custom Map Markers
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: tealGreen,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: tealGreen, blurRadius: 8)],
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  Marker(
                    point: _destinationLocation,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: sunnyYellow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: sunnyYellow, blurRadius: 10),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: oceanBlue,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Top Header Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: oceanBlue.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sunnyYellow, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isLoadingLocation
                              ? 'FETCHING GPS...'
                              : _statusMessage.toUpperCase(),
                          style: GoogleFonts.pressStart2p(
                            color: sunnyYellow,
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'NAVIGATE: ${widget.questName}',
                          style: GoogleFonts.pressStart2p(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.gps_fixed,
                      color: sunnyYellow,
                      size: 20,
                    ),
                    onPressed: _initLocation,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Details Overlay
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: oceanBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tealGreen, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.questName.toUpperCase(),
                        style: GoogleFonts.pressStart2p(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sunnyYellow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+350 XP',
                          style: GoogleFonts.pressStart2p(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'CLUE: ${widget.clueText}',
                    style: GoogleFonts.pressStart2p(
                      color: Colors.white70,
                      fontSize: 7,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: oceanBlue, width: 2),
                        ),
                      ),
                      onPressed: () {
                        QuestCompletionHelper.showCompletionDialog(
                          context,
                          questId: 'quests.id',
                        );
                      },
                      child: Text(
                        'COMPLETE QUEST',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
