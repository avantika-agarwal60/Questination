import 'package:shared_preferences/shared_preferences.dart';

class QuestService {
  static const String _storageKey = 'accepted_city_quests';

  static Future<Set<String>> getAcceptedCityIds() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey) ?? const <String>[];
    return saved.toSet();
  }

  static Future<void> saveAcceptedCityIds(Set<String> cityIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, cityIds.toList()..sort());
  }
}
