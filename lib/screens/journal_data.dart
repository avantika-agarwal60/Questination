import 'package:flutter/foundation.dart';

import '../api_service.dart';
import 'city_book.dart';

class PhotoSlotData {
  final String id;
  final String label;

  const PhotoSlotData({required this.id, required this.label});
}

class JournalPageData {
  final String id;
  final String title;
  final String? badgeUrl;
  final String date;
  final String notePlaceholder;
  final List<PhotoSlotData> slots;
  final List<String> stickers;

  const JournalPageData({
    required this.id,
    required this.title,
    this.badgeUrl,
    required this.date,
    required this.notePlaceholder,
    required this.slots,
    this.stickers = const [],
  });
}

class QuestJournalData {
  final String questId;
  final String questName;
  final String? coverUrl;
  final String? badgeUrl;
  final List<String> stickers;
  final List<JournalPageData> pages;
  final Map<String, String> photos;

  const QuestJournalData({
    required this.questId,
    required this.questName,
    required this.coverUrl,
    required this.badgeUrl,
    required this.stickers,
    required this.pages,
    required this.photos,
  });
}

Future<CityBook?> fetchCityDetailsFromApi(String cityId) async {
  final cities = await ApiService.getCities();
  for (final row in cities) {
    final city = Map<String, dynamic>.from(row as Map);
    if (city['id']?.toString() == cityId) return CityBook.fromApiRow(city);
  }
  return null;
}

Future<QuestJournalData> fetchCityJournal(String cityId) async {
  final city = await fetchCityDetailsFromApi(cityId);
  final response = await ApiService.getJournal(cityId: cityId);
  final completed = (response['completedQuests'] as List<dynamic>? ?? [])
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();
  final entries = (response['entries'] as List<dynamic>? ?? [])
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

  final savedPhotos = <String, String>{};
  final pages = <JournalPageData>[];
  for (final completion in completed) {
    final quest = Map<String, dynamic>.from(completion['quests'] as Map);
    final questId = quest['id'].toString();
    final questEntries = entries.where((entry) => entry['quest_id'] == questId);
    final photos = <({String slotId, String url})>[];

    final evidenceUrl = completion['photo_url']?.toString();
    if (evidenceUrl != null && evidenceUrl.isNotEmpty) {
      photos.add((slotId: '${questId}_evidence', url: evidenceUrl));
    }
    for (final entry in questEntries) {
      final urls = entry['photo_urls'] as List<dynamic>? ?? const [];
      for (var index = 0; index < urls.length; index++) {
        final slotId = '${entry['id']}_$index';
        photos.add((slotId: slotId, url: urls[index].toString()));
      }
    }

    if (photos.isEmpty) {
      photos.add((slotId: '${questId}_journal_photo', url: ''));
    }
    final slots = photos.map((photo) {
      if (photo.url.isNotEmpty) savedPhotos[photo.slotId] = photo.url;
      return PhotoSlotData(id: photo.slotId, label: quest['name'].toString());
    }).toList();
    final caption = questEntries
        .map((entry) => entry['caption']?.toString())
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .firstOrNull;

    pages.add(JournalPageData(
      id: questId,
      title: quest['name'].toString(),
      badgeUrl: _imageUrl(quest['quests_badges_url']),
      date: _formatDate(completion['completed_at']),
      notePlaceholder: caption ?? 'Add a note about this quest...',
      slots: slots,
      stickers: questEntries
          .map((entry) => entry['sticker_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList(),
    ));
  }

  return QuestJournalData(
    questId: cityId,
    questName: city?.name ?? cityId.toUpperCase(),
    coverUrl: city?.coverUrl,
    badgeUrl: null,
    stickers: city?.stickerUrls ?? const [],
    pages: pages,
    photos: savedPhotos,
  );
}

String? _imageUrl(Object? value) {
  final url = value?.toString().trim();
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('https://') || url.startsWith('http://')) return url;
  return null;
}

String _formatDate(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return 'JOURNAL';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

void logJournalError(Object error, StackTrace stackTrace) {
  debugPrint('Journal load failed: $error');
  debugPrintStack(stackTrace: stackTrace);
}
