import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'city_book.dart';

class QuestService {
  static const String _storageKey = 'accepted_user_quests';

  // Catalog containing Lucknow and Varanasi
  static final List<CityBook> masterCatalog = [
    CityBook(
      id: 'lko_01',
      name: 'Lucknow',
      spineColor: const Color(0xFF7DA8C4),
      coverAsset: 'assets/lkospinee.png',
      isLucknow: true,
    ),
    CityBook(
      id: 'vns_02',
      name: 'Varanasi',
      spineColor: const Color(0xFF7B3F3F),
      coverAsset: 'assets/varanasi.png',
      isVaranasi: true,
    ),
  ];

  // Get accepted quests from SharedPreferences
  static Future<List<CityBook>> getAcceptedQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawData = prefs.getString(_storageKey);

    if (rawData == null) return [];

    final List<dynamic> decoded = jsonDecode(rawData);
    return decoded.map((json) {
      final template = masterCatalog.firstWhere(
        (b) => b.id == json['id'],
        orElse: () => masterCatalog[0],
      );
      return CityBook.fromTemplateAndJson(template, json);
    }).toList();
  }

  // Save list state to local storage
  static Future<void> saveAcceptedQuests(List<CityBook> books) async {
    final prefs = await SharedPreferences.getInstance();
    final data = books.map((b) => b.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  // Unlock a quest upon GPS arrival
  static Future<void> unlockQuest(String cityId) async {
    final currentQuests = await getAcceptedQuests();

    for (var book in currentQuests) {
      if (book.id == cityId) {
        book.unlocked = true;
        break;
      }
    }

    await saveAcceptedQuests(currentQuests);
  }
}