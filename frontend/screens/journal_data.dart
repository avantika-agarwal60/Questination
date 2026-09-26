import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoSlotData {
  final String id;
  final String label;
  final bool span2;
  final bool tall;

  PhotoSlotData({
    required this.id,
    required this.label,
    this.span2 = false,
    this.tall = false,
  });

  factory PhotoSlotData.fromJson(Map<String, dynamic> json) {
    return PhotoSlotData(
      id: json['id'] ?? '',
      label: json['label'] ?? json['title'] ?? 'ADD PHOTO',
      span2: json['span2'] ?? false,
      tall: json['tall'] ?? false,
    );
  }
}

class JournalPageData {
  final String id;
  final String title;
  final String date;
  final String notePlaceholder;
  final List<PhotoSlotData> slots;
  final List<String> stickers; // <-- Added to fix the getter error!

  JournalPageData({
    required this.id,
    required this.title,
    required this.date,
    required this.notePlaceholder,
    required this.slots,
    this.stickers = const [], // Default empty list
  });

  factory JournalPageData.fromJson(Map<String, dynamic> json) {
    return JournalPageData(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      title: json['title'] ?? 'NEW QUEST PAGE',
      date: json['date'] ?? 'DAY 1',
      notePlaceholder: json['note_placeholder'] ?? 'Tap to write your thoughts...',
      slots: (json['slots'] as List? ?? [])
          .map((s) => PhotoSlotData.fromJson(s))
          .toList(),
      stickers: (json['stickers'] as List? ?? [])
          .map((s) => s.toString())
          .toList(),
    );
  }
}

/// Fetch all public sticker URLs directly from your Supabase Storage bucket ('stickers')
Future<List<String>> fetchStickerUrlsFromBucket() async {
  try {
    final supabase = Supabase.instance.client;
    final List<FileObject> objects = await supabase.storage.from('stickers').list();

    return objects
        .where((file) => !file.name.startsWith('.'))
        .map((file) => supabase.storage.from('stickers').getPublicUrl(file.name))
        .toList();
  } catch (e) {
    debugPrint('Error fetching stickers from bucket: $e');
    return [];
  }
}

/// Dynamic fetch function for journal pages
Future<List<JournalPageData>> fetchJournalPages(String questId) async {
  try {
    final response = await Supabase.instance.client
        .from('journal_pages')
        .select()
        .eq('quest_id', questId)
        .order('page_number', ascending: true);

    if (response != null && (response as List).isNotEmpty) {
      return (response as List)
          .map((row) => JournalPageData.fromJson(row))
          .toList();
    }
  } catch (e) {
    debugPrint('Supabase fetch error: $e');
  }

  return [
    JournalPageData(
      id: 'p1',
      title: 'Bada Imambada',
      date: 'DAY 01',
      notePlaceholder: 'The city opens up like a book...',
      slots: [
        PhotoSlotData(id: 's1', label: 'The monument'),
        PhotoSlotData(id: 's2', label: 'Solo picture'),
        PhotoSlotData(id: 's3', label: 'With friends'),
      ],
      stickers: [],
    ),
  ];
}