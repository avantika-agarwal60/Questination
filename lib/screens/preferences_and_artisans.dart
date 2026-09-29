import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api_service.dart';

const _green = Color(0xFF2A4A20);
const _yellow = Color(0xFFFAF179);
const _cream = Color(0xFFF4E9D4);
const _blue = Color(0xFF1684A7);

class PreferencesAndArtisansScreen extends StatefulWidget {
  final String? cityId;

  const PreferencesAndArtisansScreen({super.key, this.cityId});

  @override
  State<PreferencesAndArtisansScreen> createState() =>
      _PreferencesAndArtisansScreenState();
}

class _PreferencesAndArtisansScreenState
    extends State<PreferencesAndArtisansScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _categories = [];
  List<dynamic> _artisans = [];
  List<dynamic> _recommendations = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PreferencesAndArtisansScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cityId != oldWidget.cityId) _load();
  }

  Future<void> _load() async {
    final cityId = widget.cityId;
    if (cityId == null || cityId.isEmpty) {
      setState(() {
        _loading = false;
        _categories = [];
        _artisans = [];
        _recommendations = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getCraftCategories(cityId),
        ApiService.getArtisans(cityId),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0];
        _artisans = results[1];
        _loading = false;
      });
      await _loadRecommendations();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleCategory(String id) async {
    if (_selectedIds.contains(id) && _selectedIds.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keep at least one craft preference selected.'),
        ),
      );
      return;
    }
    final previous = Set<String>.from(_selectedIds);
    final next = Set<String>.from(_selectedIds);
    if (!next.add(id)) next.remove(id);
    setState(() => _selectedIds
      ..clear()
      ..addAll(next));
    try {
      await ApiService.saveCraftPreferences(next.toList());
      await _loadRecommendations();
    } catch (error) {
      if (mounted) {
        setState(() => _selectedIds
          ..clear()
          ..addAll(previous));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final recommendations = await ApiService.getRecommendations();
      if (mounted) setState(() => _recommendations = recommendations);
    } catch (_) {
      if (mounted) setState(() => _recommendations = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.cityId;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: Text('ARTISANS & CRAFTS',
            style: GoogleFonts.pressStart2p(fontSize: 9, color: _green)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center)))
              : city == null
                  ? const Center(
                      child: Text('Select a city to see local artisans.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('CITY: ${city.toUpperCase()}',
                            style: GoogleFonts.pressStart2p(
                                fontSize: 7, color: _blue)),
                        const SizedBox(height: 16),
                        Text('CRAFT PREFERENCES',
                            style: GoogleFonts.pressStart2p(
                                fontSize: 8, color: _green)),
                        const SizedBox(height: 10),
                        if (_categories.isEmpty)
                          Text('No craft categories configured for this city.',
                              style: GoogleFonts.vt323(
                                  fontSize: 18, color: _green))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((row) {
                              final category =
                                  Map<String, dynamic>.from(row as Map);
                              final id = category['id'].toString();
                              final name =
                                  (category['name'] ?? 'Craft').toString();
                              return FilterChip(
                                selected: _selectedIds.contains(id),
                                label: Text(name.toUpperCase(),
                                    style:
                                        GoogleFonts.pressStart2p(fontSize: 6)),
                                selectedColor: _yellow,
                                onSelected: (_) => _toggleCategory(id),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 22),
                        Text('RECOMMENDED ARTISANS',
                            style: GoogleFonts.pressStart2p(
                                fontSize: 8, color: _green)),
                        const SizedBox(height: 10),
                        ..._recommendations.map(
                            (row) => _artisanTile(row, recommendation: true)),
                        if (_recommendations.isEmpty)
                          Text(
                              'Select craft preferences to see recommendations.',
                              style: GoogleFonts.vt323(
                                  fontSize: 18, color: _green)),
                        const SizedBox(height: 22),
                        Text('ARTISANS IN THIS CITY',
                            style: GoogleFonts.pressStart2p(
                                fontSize: 8, color: _green)),
                        const SizedBox(height: 10),
                        ..._artisans.map((row) => _artisanTile(row)),
                        if (_artisans.isEmpty)
                          Text('No artisans listed for this city yet.',
                              style: GoogleFonts.vt323(
                                  fontSize: 18, color: _green)),
                      ],
                    ),
    );
  }

  Widget _artisanTile(Object raw, {bool recommendation = false}) {
    final artisan = Map<String, dynamic>.from(raw as Map);
    final category = artisan['craft_category'];
    final categoryName = category is Map ? category['name']?.toString() : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _green, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (artisan['shop_name'] ?? artisan['name'] ?? 'ARTISAN')
                .toString()
                .toUpperCase(),
            style: GoogleFonts.pressStart2p(fontSize: 7, color: _blue),
          ),
          if (categoryName != null) ...[
            const SizedBox(height: 6),
            Text(categoryName,
                style: GoogleFonts.vt323(fontSize: 17, color: _green)),
          ],
          if (artisan['description'] != null) ...[
            const SizedBox(height: 4),
            Text(artisan['description'].toString(),
                style: GoogleFonts.vt323(fontSize: 16, color: Colors.black54)),
          ],
          if (recommendation)
            Align(
              alignment: Alignment.centerRight,
              child: Text('MATCHED TO YOUR CRAFTS',
                  style: GoogleFonts.pressStart2p(fontSize: 5, color: _green)),
            ),
        ],
      ),
    );
  }
}
