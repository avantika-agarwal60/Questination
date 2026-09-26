import 'package:flutter/foundation.dart';

class XpManager extends ChangeNotifier {
  static final XpManager _instance = XpManager._internal();
  factory XpManager() => _instance;
  XpManager._internal();

  int _xp = 0;
  final Set<String> _awardedSlots = {};
  final Set<String> _completedJournals = {};

  int get xp => _xp;

  // Each stage = 100 XP
  int get stage => (_xp ~/ 100) + 1;
  double get stageProgress => (_xp % 100) / 100.0;

  // +50 XP when a quest is accepted
  void addQuestXp() {
    _xp += 50;
    notifyListeners();
  }

  // +10 XP for the FIRST photo added to a slot — editing the same slot again gives nothing
  void addPhotoXp(String slotId) {
    if (_awardedSlots.contains(slotId)) return;
    _awardedSlots.add(slotId);
    _xp += 10;
    notifyListeners();
  }

  // +50 XP once per journal when all slots are filled for the first time
  void checkJournalComplete(String journalId, Set<String> allSlots, Set<String> filledSlots) {
    if (_completedJournals.contains(journalId)) return;
    if (allSlots.every(filledSlots.contains)) {
      _completedJournals.add(journalId);
      _xp += 50;
      notifyListeners();
    }
  }
}
