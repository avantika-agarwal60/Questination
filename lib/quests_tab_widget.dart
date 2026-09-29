import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

class QuestsListScreen extends StatefulWidget {
  final String? cityId;
  final ValueChanged<String>? onCityChanged;
  final Function(String questId, String cityId)? onQuestSelected;

  const QuestsListScreen({
    super.key,
    this.cityId,
    this.onCityChanged,
    this.onQuestSelected,
  });

  @override
  State<QuestsListScreen> createState() => _QuestsListScreenState();
}

class _QuestsListScreenState extends State<QuestsListScreen> {
  // Original Palette Constants
  static const Color creamBg = Color(0xFFF4F1EA);
  static const Color oceanBlue = Color(0xFF1684A7);
  static const Color tealGreen = Color(0xFF0EA391);
  static const Color cardBorderColor = Color(0xFF1684A7);

  List<dynamic> _quests = [];
  List<Map<String, dynamic>> _cities = [];
  List<dynamic> _allQuests = [];
  String? _selectedCityId;
  bool _isLoading = true;
  bool _isDetectingCity = false;

  @override
  void initState() {
    super.initState();
    _selectedCityId = widget.cityId;
    _loadCityQuests(detectLocation: widget.cityId == null);
  }

  @override
  void didUpdateWidget(covariant QuestsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityId != widget.cityId && widget.cityId != _selectedCityId) {
      setState(() {
        _selectedCityId = widget.cityId;
        _quests = _questsForCity(widget.cityId);
      });
    }
  }

  Future<void> _loadCityQuests({bool detectLocation = false}) async {
    setState(() {
      _isLoading = true;
      _isDetectingCity = detectLocation;
    });
    try {
      final results = await Future.wait([
        ApiService.getCities(),
        ApiService.getQuests(),
      ]);
      final cities = results[0]
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final quests = results[1];
      var cityId = _selectedCityId ?? widget.cityId;
      if (detectLocation || cityId == null) {
        cityId = await _nearestSupportedCity(cities, quests);
      }
      if (mounted) {
        setState(() {
          _cities = cities;
          _allQuests = quests;
          _selectedCityId = cityId;
          _quests = _questsForCity(cityId);
          _isLoading = false;
          _isDetectingCity = false;
        });
        if (cityId != null) widget.onCityChanged?.call(cityId);
      }
    } catch (e) {
      debugPrint('Error loading quests: $e');
      if (mounted) {
        setState(() {
          _quests = [];
          _isLoading = false;
          _isDetectingCity = false;
        });
      }
    }
  }

  Future<String?> _nearestSupportedCity(
    List<Map<String, dynamic>> cities,
    List<dynamic> quests,
  ) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      String? nearestCityId;
      var nearestDistance = double.infinity;

      for (final city in cities) {
        final cityId = city['id']?.toString();
        if (cityId == null) continue;
        final locations = quests
            .map((row) => Map<String, dynamic>.from(row as Map))
            .where((quest) =>
                quest['city_id']?.toString() == cityId &&
                quest['lat'] is num &&
                quest['lng'] is num)
            .toList();
        if (locations.isEmpty) continue;

        final latitude = locations
                .map((quest) => (quest['lat'] as num).toDouble())
                .reduce((sum, value) => sum + value) /
            locations.length;
        final longitude = locations
                .map((quest) => (quest['lng'] as num).toDouble())
                .reduce((sum, value) => sum + value) /
            locations.length;
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          latitude,
          longitude,
        );
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestCityId = cityId;
        }
      }
      return nearestCityId;
    } catch (error) {
      debugPrint('Could not detect city from location: $error');
      return null;
    }
  }

  List<dynamic> _questsForCity(String? cityId) {
    if (cityId == null) return [];
    return _allQuests.where((row) {
      final quest = row as Map;
      return quest['city_id']?.toString() == cityId;
    }).toList();
  }

  void _selectCity(String? cityId) {
    setState(() {
      _selectedCityId = cityId;
      _quests = _questsForCity(cityId);
    });
    if (cityId != null) widget.onCityChanged?.call(cityId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header: Logo & Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: tealGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.explore,
                      color: Color(0xFFFAF179),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Questination',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 18,
                      color: tealGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'YOUR ADVENTURES, COLLECTED',
                style: GoogleFonts.pressStart2p(
                  fontSize: 9,
                  color: oceanBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_selectedCityId),
                      initialValue: _cities.any((city) =>
                              city['id']?.toString() == _selectedCityId)
                          ? _selectedCityId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'QUEST CITY',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: Text(
                        _isDetectingCity ? 'DETECTING CITY…' : 'SELECT A CITY',
                        style: GoogleFonts.pressStart2p(fontSize: 7),
                      ),
                      items: _cities.map((city) {
                        final id = city['id'].toString();
                        return DropdownMenuItem(
                          value: id,
                          child: Text(
                            city['name']?.toString() ?? id,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _isLoading ? null : _selectCity,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Detect my city',
                    onPressed: _isLoading
                        ? null
                        : () => _loadCityQuests(detectLocation: true),
                    icon: const Icon(Icons.my_location, color: tealGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Quest Cards List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: tealGreen),
                    )
                  : _selectedCityId == null
                      ? Center(
                          child: Text(
                            'ALLOW LOCATION OR SELECT A CITY',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.pressStart2p(
                              fontSize: 8,
                              color: oceanBlue,
                            ),
                          ),
                        )
                      : _quests.isEmpty
                          ? Center(
                              child: Text(
                                'NO QUESTS FOUND FOR THIS CITY',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 8,
                                  color: oceanBlue,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _quests.length,
                              itemBuilder: (context, index) {
                                final quest = _quests[index];
                                final name = quest['name'] ?? 'Unknown Quest';
                                final desc = quest['description'] ?? '';
                                final xp = quest['xp'] ?? 150;
                                final questId = quest['id']?.toString();
                                final cityId =
                                    quest['city_id']?.toString() ?? 'lucknow';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    onTap: () {
                                      if (widget.onQuestSelected != null &&
                                          questId != null) {
                                        widget.onQuestSelected!(
                                            questId, cityId);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: cardBorderColor,
                                          width: 2,
                                        ),
                                      ),
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
                                                  name,
                                                  style:
                                                      GoogleFonts.pressStart2p(
                                                    fontSize: 10,
                                                    color: oceanBlue,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '+$xp XP',
                                                style: GoogleFonts.pressStart2p(
                                                  fontSize: 9,
                                                  color: tealGreen,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (desc.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              desc,
                                              style: GoogleFonts.pressStart2p(
                                                fontSize: 7,
                                                color: Colors.black54,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ],
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
}
