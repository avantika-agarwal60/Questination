class PageData {
  final String templateType; // e.g., 'single_photo', 'photo_grid'
  final String title;
  final String description;
  final List<String> slotIds;

  PageData({
    required this.templateType,
    required this.title,
    required this.description,
    required this.slotIds,
  });

  factory PageData.fromJson(Map<String, dynamic> json) {
    return PageData(
      templateType: json['template_type'] ?? 'single_photo',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      slotIds: List<String>.from(json['slot_ids'] ?? []),
    );
  }
}

class SpreadData {
  final PageData leftPage;
  final PageData rightPage;

  SpreadData({required this.leftPage, required this.rightPage});

  factory SpreadData.fromJson(Map<String, dynamic> json) {
    return SpreadData(
      leftPage: PageData.fromJson(json['left_page']),
      rightPage: PageData.fromJson(json['right_page']),
    );
  }
}

class QuestJournalTheme {
  final String questId;
  final String title;
  final String coverUrl;
  final List<SpreadData> spreads;

  QuestJournalTheme({
    required this.questId,
    required this.title,
    required this.coverUrl,
    required this.spreads,
  });

  factory QuestJournalTheme.fromJson(Map<String, dynamic> json) {
    return QuestJournalTheme(
      questId: json['quest_id'],
      title: json['title'],
      coverUrl: json['cover_url'],
      spreads: (json['spreads'] as List)
          .map((s) => SpreadData.fromJson(s))
          .toList(),
    );
  }
}