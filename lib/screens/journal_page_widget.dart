import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'journal_data.dart';
import 'photo_service.dart';

const _paper = Color(0xFFF4E9D4);
const _brown = Color(0xFF3A2810);
const _brownMid = Color(0xFF7A5830);
const _accent = Color(0xFF8A7050);
const _green = Color(0xFF2A4A20);
const _slotBackground = Color(0xFFEDE0C4);

class JournalPageWidget extends StatelessWidget {
  final JournalPageData page;
  final Map<String, String> photos;
  final ValueChanged<MapEntry<String, String>> onPhotoAdded;
  final int pageNum;
  final bool isLeft;
  final List<String> stickerUrls;
  final String questId;

  const JournalPageWidget({
    super.key,
    required this.page,
    required this.photos,
    required this.onPhotoAdded,
    required this.pageNum,
    required this.isLeft,
    required this.questId,
    this.stickerUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _paper,
        border: Border(
          top: const BorderSide(color: Color(0xFFC8B890), width: 3),
          bottom: const BorderSide(color: Color(0xFFC8B890), width: 3),
          left: isLeft
              ? const BorderSide(color: Color(0xFFC8B890), width: 3)
              : BorderSide.none,
          right: isLeft
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFC8B890), width: 3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  page.title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.pressStart2p(fontSize: 7, color: _brown),
                ),
              ),
              const SizedBox(width: 8),
              _buildQuestBadge(),
              const SizedBox(width: 8),
              Text(
                page.date,
                style: GoogleFonts.pressStart2p(fontSize: 5, color: _brownMid),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildPhotoGrid()),
          const SizedBox(height: 6),
          Text(
            page.notePlaceholder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.vt323(
              fontSize: 13,
              color: _brownMid,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              ...page.stickers.map((sticker) => Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Text(sticker, style: const TextStyle(fontSize: 14)),
                  )),
              ...stickerUrls.take(3).map((url) => Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Image.network(
                      url,
                      width: 16,
                      height: 16,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.star,
                        size: 14,
                        color: _accent,
                      ),
                    ),
                  )),
              const Spacer(),
              Text('P.$pageNum',
                  style:
                      GoogleFonts.pressStart2p(fontSize: 5, color: _brownMid)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestBadge() {
    final badgeUrl = page.badgeUrl;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE6D3A0),
        border: Border.all(color: _accent, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: badgeUrl == null
          ? const Icon(Icons.workspace_premium, size: 18, color: _brownMid)
          : Image.network(
              badgeUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.workspace_premium,
                  size: 18, color: _brownMid),
            ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: page.slots.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: page.slots.length == 1 ? 1 : 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemBuilder: (context, index) {
        final slot = page.slots[index];
        return _PhotoSlot(
          slot: slot,
          photoUrl: photos[slot.id],
          questId: questId,
          onUploaded: (url) => onPhotoAdded(MapEntry(slot.id, url)),
        );
      },
    );
  }
}

class _PhotoSlot extends StatefulWidget {
  final PhotoSlotData slot;
  final String? photoUrl;
  final String questId;
  final ValueChanged<String> onUploaded;

  const _PhotoSlot({
    required this.slot,
    required this.photoUrl,
    required this.questId,
    required this.onUploaded,
  });

  @override
  State<_PhotoSlot> createState() => _PhotoSlotState();
}

class _PhotoSlotState extends State<_PhotoSlot> {
  bool _uploading = false;

  Future<void> _uploadPhoto() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final url = await PhotoService().pickAndUploadPhoto(
        questId: widget.questId,
        slotId: widget.slot.id,
      );
      if (mounted && url != null) widget.onUploaded(url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.photoUrl;
    return GestureDetector(
      onTap: _uploadPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: _slotBackground,
          border: Border.all(color: _accent, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              )
            else
              Center(
                child: Text(
                  '+ ADD PHOTO\n${widget.slot.label}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 6,
                    height: 1.8,
                    color: _green,
                  ),
                ),
              ),
            if (_uploading)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
