import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'city_book.dart';
import 'journal_data.dart';
import 'journal_page_widget.dart';
import 'page_flip_widget.dart';

class PixelJournalMainScreen extends StatefulWidget {
  final String? cityId;
  final String? visitedQuestId;
  final bool gpsVerified;
  final bool qrVerified;

  const PixelJournalMainScreen({
    super.key,
    this.cityId,
    this.visitedQuestId,
    this.gpsVerified = false,
    this.qrVerified = false,
  });

  @override
  State<PixelJournalMainScreen> createState() => _PixelJournalMainScreenState();
}

class _PixelJournalMainScreenState extends State<PixelJournalMainScreen> {
  QuestJournalData? _journal;
  CityBook? _cityBook;
  Object? _error;
  bool _loading = true;
  bool _showCover = true;
  int _pageIndex = 0;
  final Map<String, String> _savedPhotos = {};

  @override
  void initState() {
    super.initState();
    final cityId = widget.cityId;
    if (cityId == null || cityId.isEmpty) {
      _loading = false;
    } else {
      _load(cityId);
    }
  }

  Future<void> _load(String cityId) async {
    try {
      final city = await fetchCityDetailsFromApi(cityId);
      final journal = await fetchCityJournal(cityId);
      if (!mounted) return;
      setState(() {
        _cityBook = city;
        _journal = journal;
        _savedPhotos.addAll(journal.photos);
        _loading = false;
        if (widget.visitedQuestId != null) {
          final index = journal.pages
              .indexWhere((page) => page.id == widget.visitedQuestId);
          if (index >= 0) _pageIndex = index;
          _showCover = false;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  bool get _unlocked => widget.gpsVerified && widget.qrVerified;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4E9D4),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _message('Could not load this journal.\n$_error');
    }
    if (_journal == null) return _message('Choose a city to open its journal.');
    if (_showCover) return _coverView();
    return _pagesView();
  }

  Widget _message(String message) => Scaffold(
        backgroundColor: const Color(0xFFF4E9D4),
        appBar: AppBar(title: const Text('JOURNAL')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.vt323(
                  fontSize: 20, color: const Color(0xFF2A4A20)),
            ),
          ),
        ),
      );

  Widget _coverView() {
    final journal = _journal!;
    final imageUrl = journal.coverUrl ?? _cityBook?.spineUrl;
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5C8),
      appBar: AppBar(title: Text(journal.questName)),
      body: Center(
        child: GestureDetector(
          onTap: () {
            if (!_unlocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Complete a quest in this city to unlock its journal.')),
              );
              return;
            }
            setState(() => _showCover = false);
          },
          child: Container(
            width: 310,
            height: 480,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _unlocked ? const Color(0xFF7AA6B9) : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2A4A20), width: 3),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  journal.questName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(
                      fontSize: 12, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _unlocked
                      ? 'CITY JOURNAL UNLOCKED'
                      : 'LOCKED - COMPLETE A QUEST',
                  style: GoogleFonts.vt323(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: 190,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6D3A0),
                      border: Border.all(color: Colors.white, width: 4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl == null
                        ? const Icon(Icons.menu_book,
                            size: 72, color: Color(0xFF2A4A20))
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.menu_book, size: 72),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    _unlocked ? 'TAP COVER TO OPEN' : 'LOCKED JOURNAL',
                    style: GoogleFonts.pressStart2p(
                        fontSize: 7, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pagesView() {
    final journal = _journal!;
    if (journal.pages.isEmpty) {
      return _message('No completed quests in this city yet.');
    }
    _pageIndex = _pageIndex.clamp(0, journal.pages.length - 1);
    final page = journal.pages[_pageIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFF4E9D4),
      appBar: AppBar(
        title: Text(journal.questName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showCover = true),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(child: _buildPage(journal, page)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _pageIndex > 0
                      ? () => setState(() => _pageIndex--)
                      : null,
                  child: const Text('PREV'),
                ),
                Text('${_pageIndex + 1} / ${journal.pages.length}'),
                TextButton(
                  onPressed: _pageIndex < journal.pages.length - 1
                      ? () => setState(() => _pageIndex++)
                      : null,
                  child: const Text('NEXT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(QuestJournalData journal, JournalPageData page) {
    final current = JournalPageWidget(
      page: page,
      photos: _savedPhotos,
      onPhotoAdded: (entry) =>
          setState(() => _savedPhotos[entry.key] = entry.value),
      pageNum: _pageIndex + 1,
      isLeft: true,
      stickerUrls: journal.stickers,
      questId: page.id,
    );
    if (journal.pages.length < 2) return current;
    final nextIndex = (_pageIndex + 1) % journal.pages.length;
    final next = journal.pages[nextIndex];
    return PageFlipWidget(
      frontPage: current,
      backPage: JournalPageWidget(
        page: next,
        photos: _savedPhotos,
        onPhotoAdded: (entry) =>
            setState(() => _savedPhotos[entry.key] = entry.value),
        pageNum: nextIndex + 1,
        isLeft: false,
        stickerUrls: journal.stickers,
        questId: next.id,
      ),
      pivotOnLeft: _pageIndex < journal.pages.length - 1,
      onFlipComplete: () {},
    );
  }
}
