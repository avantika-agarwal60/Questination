import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'journal_data.dart';
import 'journal_page_widget.dart';
import 'xp_manager.dart';

class PixelJournalMainScreen extends StatefulWidget {
  // Was hardcoded to always show Lucknow before — every city opened the
  // same journal. Now the caller (BookshelfScreen) passes which city/quest
  // this journal is for.
  final String citySlug;
  final String cityName;

  const PixelJournalMainScreen({
    super.key,
    this.citySlug = 'lucknow',
    this.cityName = 'LUCKNOW',
  });

  @override
  State<PixelJournalMainScreen> createState() => _PixelJournalMainScreenState();
}

class _PixelJournalMainScreenState extends State<PixelJournalMainScreen> {
  bool _isLoading = true;
  bool _showCover = true;
  int _currentPageIndex = 0;

  List<JournalPageData> _pages = [];
  List<String> _bucketStickers = [];
  final Map<String, List<String>> _placedStickers = {};
  final Map<String, String> _savedPhotos = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pages = await fetchJournalPages(widget.citySlug);
    final stickers = await fetchStickerUrlsFromBucket();

    if (mounted) {
      setState(() {
        _pages = pages;
        _bucketStickers = stickers;
        _isLoading = false;
      });
    }
  }

  void _openStickerSelector(String pageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF4E9D4),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADD STICKER FROM BUCKET',
                style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF2A4A20)),
              ),
              const SizedBox(height: 12),
              _bucketStickers.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Text(
                          'No stickers found in Supabase bucket',
                          style: GoogleFonts.vt323(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _bucketStickers.length,
                        itemBuilder: (context, index) {
                          final url = _bucketStickers[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _placedStickers.putIfAbsent(pageId, () => []);
                                _placedStickers[pageId]!.add(url);
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: Image.network(url, fit: BoxFit.contain),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _handlePhotoAdded(MapEntry<String, String> photo) {
    setState(() {
      _savedPhotos[photo.key] = photo.value;
    });

    // Was never called before — XpManager.addPhotoXp/checkJournalComplete
    // existed but nothing in this screen invoked them, so photos never
    // earned XP.
    XpManager().addPhotoXp(photo.key);

    if (_pages.isNotEmpty) {
      final currentPage = _pages[_currentPageIndex];
      final allSlotIds = currentPage.slots.map((s) => s.id).toSet();
      final filledSlotIds = _savedPhotos.keys.toSet();
      XpManager().checkJournalComplete(currentPage.id, allSlotIds, filledSlotIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2A4A20)),
        ),
      );
    }

    if (_showCover) {
      return _buildCoverScreen();
    }

    return _buildJournalView();
  }

  Widget _buildCoverScreen() {
    return GestureDetector(
      onTap: () => setState(() => _showCover = false),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3E5C8),
        body: Center(
          child: Container(
            width: 320,
            height: 520,
            decoration: BoxDecoration(
              color: const Color(0xFF7AA6B9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2A4A20), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332A4A20),
                  offset: Offset(0, 10),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 28),
                Text(
                  widget.cityName,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'TRAVEL JOURNAL',
                  style: GoogleFonts.vt323(
                    fontSize: 22,
                    color: Colors.white70,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 190,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6D3A0),
                        border: Border.all(color: Colors.white, width: 4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFCDBB7B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '✦',
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 42,
                                    color: const Color(0xFF2A4A20),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 18,
                            left: 20,
                            right: 20,
                            child: Text(
                              'MEMORIES OF THE CITY',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.pressStart2p(
                                fontSize: 7,
                                color: const Color(0xFF2A4A20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Text(
                    'TAP TO OPEN',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 7,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJournalView() {
    if (_pages.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4E9D4),
        body: Center(
          child: Text(
            'No journal pages found',
            style: GoogleFonts.vt323(fontSize: 24, color: const Color(0xFF2A4A20)),
          ),
        ),
      );
    }

    final page = _pages[_currentPageIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF4E9D4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4E9D4),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          '✦ ${widget.cityName} ✦',
          style: GoogleFonts.pressStart2p(fontSize: 8, color: const Color(0xFF2A4A20)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2A4A20)),
          onPressed: () => setState(() => _showCover = true),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Column(
          children: [
            Expanded(
              child: JournalPageWidget(
                page: page,
                photos: _savedPhotos,
                onPhotoAdded: _handlePhotoAdded,
                pageNum: _currentPageIndex + 1,
                isLeft: true,
                stickerUrls: _bucketStickers,
                questId: widget.citySlug,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavButton(
                  text: 'PREV',
                  enabled: _currentPageIndex > 0,
                  onPressed: _currentPageIndex > 0
                      ? () => setState(() => _currentPageIndex--)
                      : null,
                ),
                Text(
                  '${_currentPageIndex + 1} / ${_pages.length}',
                  style: GoogleFonts.pressStart2p(fontSize: 7, color: const Color(0xFF2A4A20)),
                ),
                _buildNavButton(
                  text: 'NEXT',
                  enabled: _currentPageIndex < _pages.length - 1,
                  onPressed: _currentPageIndex < _pages.length - 1
                      ? () => setState(() => _currentPageIndex++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required String text,
    required bool enabled,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? const Color(0xFF2A4A20) : Colors.grey.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(
        text,
        style: GoogleFonts.pressStart2p(fontSize: 6),
      ),
    );
  }
}