import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api_service.dart';
import 'city_book.dart';
import 'pixel_journal.dart';
import 'quest_service.dart';

const _green = Color(0xFF2A4A20);
const _cream = Color(0xFFFFF8E1);
const _yellow = Color(0xFFFFD54F);

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen>
    with SingleTickerProviderStateMixin {
  final List<CityBook> _books = [];
  final List<CityBook> _questPool = [];
  late final AnimationController _newBookController;
  int _questIndex = 0;
  int? _newBookIndex;
  String _selectedJournalCityId = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _newBookController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadBooks();
  }

  @override
  void dispose() {
    _newBookController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    try {
      final results = await Future.wait([
        ApiService.getCities(),
        ApiService.getQuests(),
        QuestService.getAcceptedCityIds(),
      ]);
      final cities = results[0] as List<dynamic>;
      final quests = results[1] as List<dynamic>;
      final acceptedIds = results[2] as Set<String>;
      final questsByCity = <String, List<Map<String, dynamic>>>{};
      for (final row in quests) {
        final quest = Map<String, dynamic>.from(row as Map);
        final cityId = quest['city_id']?.toString();
        if (cityId != null) {
          questsByCity.putIfAbsent(cityId, () => []).add(quest);
        }
      }

      final available = <CityBook>[];
      for (final row in cities) {
        final city = Map<String, dynamic>.from(row as Map);
        final cityId = city['id']?.toString() ?? '';
        if (cityId.isEmpty || (questsByCity[cityId]?.isEmpty ?? true)) continue;
        final book = CityBook.fromApiRow(city);
        book.isQuestAccepted = acceptedIds.contains(cityId);
        try {
          final journal = await ApiService.getJournal(cityId: cityId);
          book.unlocked =
              (journal['completedQuests'] as List? ?? []).isNotEmpty;
        } catch (_) {
          book.unlocked = false;
        }
        available.add(book);
      }

      if (!mounted) return;
      setState(() {
        _books
          ..clear()
          ..addAll(available.where((book) => book.isQuestAccepted));
        _questPool
          ..clear()
          ..addAll(available.where((book) => !book.isQuestAccepted));
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _offerNextQuest() async {
    if (_questIndex >= _questPool.length) return;
    final book = _questPool[_questIndex];
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        title: Text(
          'NEW QUEST: ${book.name.toUpperCase()}',
          style: GoogleFonts.pressStart2p(fontSize: 9, color: _green),
        ),
        content: Text(
          'A new city adventure awaits. Accept ${book.name}?',
          style: GoogleFonts.vt323(fontSize: 20, color: _green),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('DECLINE'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ACCEPT'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (accepted == true) {
      setState(() {
        book.isQuestAccepted = true;
        _newBookIndex = _books.length;
        _books.add(book);
        _questIndex++;
      });
      _newBookController.forward(from: 0);
      await QuestService.saveAcceptedCityIds(
        _books.map((item) => item.cityId).toSet(),
      );
    } else if (accepted == false) {
      setState(() => _questIndex++);
    }
  }

  void _openBook(CityBook book) {
    if (!book.unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Complete a quest in ${book.name} to unlock its journal.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PixelJournalMainScreen(
        cityId: book.cityId,
        gpsVerified: true,
        qrVerified: true,
      ),
    ));
  }

  List<CityBook> get _visibleBooks => _selectedJournalCityId.isEmpty
      ? _books
      : _books.where((book) => book.cityId == _selectedJournalCityId).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Column(
                children: [
                  const Icon(Icons.auto_stories, size: 44, color: _green),
                  const SizedBox(height: 8),
                  Text(
                    'YOUR ADVENTURES, COLLECTED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pressStart2p(fontSize: 8, color: _green),
                  ),
                ],
              ),
            ),
            if (!_loading && _error == null && _books.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'JOURNAL CITY',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedJournalCityId,
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('ALL ACCEPTED CITIES'),
                        ),
                        ..._books.map((book) => DropdownMenuItem(
                              value: book.cityId,
                              child: Text(book.name),
                            )),
                      ],
                      onChanged: (cityId) {
                        if (cityId != null) {
                          setState(() => _selectedJournalCityId = cityId);
                        }
                      },
                    ),
                  ),
                ),
              ),
            if (!_loading && _error == null && _books.isNotEmpty)
              const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _green))
                  : _error != null
                      ? Center(
                          child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Could not load city books.\n$_error',
                              textAlign: TextAlign.center),
                        ))
                      : _visibleBooks.isEmpty
                          ? Center(
                              child: Text(
                                'YOUR BOOKSHELF IS EMPTY\nACCEPT A CITY QUEST TO BEGIN',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.pressStart2p(
                                    fontSize: 8, height: 1.8, color: _green),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _visibleBooks.length,
                              itemBuilder: (context, index) {
                                final book = _visibleBooks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ScaleTransition(
                                    scale: index == _newBookIndex
                                        ? CurvedAnimation(
                                            parent: _newBookController,
                                            curve: Curves.easeOutBack)
                                        : const AlwaysStoppedAnimation(1),
                                    child: InkWell(
                                      onTap: () => _openBook(book),
                                      child: Container(
                                        height: 96,
                                        decoration: BoxDecoration(
                                          color: book.spineColor,
                                          border: Border.all(
                                              color: _green, width: 2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            if (book.spineUrl != null)
                                              Image.network(
                                                book.spineUrl!,
                                                fit: BoxFit.fill,
                                                errorBuilder: (_, __, ___) =>
                                                    ColoredBox(
                                                        color: book.spineColor),
                                              )
                                            else
                                              ColoredBox(
                                                  color: book.spineColor),
                                            const ColoredBox(
                                                color: Color(0x33000000)),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Center(
                                                    child: Text(
                                                      book.name.toUpperCase(),
                                                      style: GoogleFonts
                                                          .pressStart2p(
                                                        fontSize: 10,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 18),
                                                  child: Text(book.emoji,
                                                      style: const TextStyle(
                                                          fontSize: 30)),
                                                ),
                                                if (!book.unlocked)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 14),
                                                    child: Icon(Icons.lock,
                                                        color: Colors.white),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            if (!_loading && _error == null && _questIndex < _questPool.length)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _offerNextQuest,
                    icon: const Icon(Icons.add),
                    label: Text('ACCEPT NEW QUEST',
                        style: GoogleFonts.pressStart2p(fontSize: 8)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      backgroundColor: _yellow.withValues(alpha: 0.2),
                      side: const BorderSide(color: _green, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
