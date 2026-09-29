import 'package:flutter/material.dart';

class CityBook {
  final String id;
  final String cityId;
  final String name;
  final String emoji;
  final Color spineColor;
  final Color labelColor;
  final String? coverUrl;
  final String? spineUrl;
  final List<String> stickerUrls;
  bool isQuestAccepted;
  bool unlocked;

  CityBook({
    required this.id,
    required this.cityId,
    required this.name,
    required this.spineColor,
    this.emoji = '📖',
    this.labelColor = const Color(0xFF1A2A3A),
    this.coverUrl,
    this.spineUrl,
    this.stickerUrls = const [],
    this.isQuestAccepted = false,
    this.unlocked = false,
  });

  factory CityBook.fromApiRow(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    final name = row['name']?.toString() ?? 'Unknown City';
    final isLucknow = name.toLowerCase() == 'lucknow';
    return CityBook(
      id: id,
      cityId: id,
      name: name,
      emoji: isLucknow ? '🏛️' : '🪔',
      spineColor: isLucknow ? const Color(0xFF7DA8C4) : const Color(0xFF7B3F3F),
      spineUrl: _publicUrl(row['cities_jspine_url']),
      coverUrl: _publicUrl(row['cities_jcover_url']),
      stickerUrls: (row['cities_stickers_url'] as List<dynamic>? ?? [])
          .map(_publicUrl)
          .whereType<String>()
          .toList(),
    );
  }

  static String? _publicUrl(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text.startsWith('https://') || text.startsWith('http://')
        ? text
        : null;
  }
}
