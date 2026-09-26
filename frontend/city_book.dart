import 'package:flutter/material.dart';

/// The single CityBook model — home_screen.dart and quest_service.dart
/// used to each define their OWN CityBook class with different fields,
/// which meant QuestService's save/load couldn't actually plug into
/// BookshelfScreen. This is the merged version both files now import.
class CityBook {
  final String id;
  final String name;
  final String emoji;
  final Color spineColor;
  final Color labelColor;
  final String? coverAsset; // local asset fallback, e.g. 'assets/lkospinee.png'
  final String? coverUrl; // Supabase 'illustration-assets' URL, if you have one
  final bool isLucknow;
  final bool isVaranasi;
  bool isQuestAccepted;
  bool unlocked;

  CityBook({
    required this.id,
    required this.name,
    this.emoji = '📖',
    required this.spineColor,
    this.labelColor = const Color(0xFF1A2A3A),
    this.coverAsset,
    this.coverUrl,
    this.isLucknow = false,
    this.isVaranasi = false,
    this.isQuestAccepted = false,
    this.unlocked = false,
  });

  /// Only the bits that change per-user get persisted — everything else
  /// (colors, art) is restored from [QuestService.masterCatalog] via
  /// [fromTemplateAndJson] below, so this stays a tiny local blob.
  Map<String, dynamic> toJson() => {
        'id': id,
        'isQuestAccepted': isQuestAccepted,
        'unlocked': unlocked,
      };

  /// Rehydrates a saved SharedPreferences entry against its static
  /// template from the master catalog.
  factory CityBook.fromTemplateAndJson(
    CityBook template,
    Map<String, dynamic> json,
  ) {
    return CityBook(
      id: template.id,
      name: template.name,
      emoji: template.emoji,
      spineColor: template.spineColor,
      labelColor: template.labelColor,
      coverAsset: template.coverAsset,
      coverUrl: template.coverUrl,
      isLucknow: template.isLucknow,
      isVaranasi: template.isVaranasi,
      isQuestAccepted: json['isQuestAccepted'] ?? false,
      unlocked: json['unlocked'] ?? false,
    );
  }

  /// For a row coming straight from a shared Supabase table (e.g. if you
  /// and your teammate end up with a `cities` or `quests` table the map
  /// screen also reads from).
  factory CityBook.fromSupabaseRow(Map<String, dynamic> row) {
    return CityBook(
      id: row['id']?.toString() ?? '',
      name: row['name'] ?? '',
      coverUrl: row['illustration_url'],
      unlocked: row['unlocked'] ?? false,
      spineColor: const Color(0xFF7B3F3F),
    );
  }
}