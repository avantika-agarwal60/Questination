import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'journal_data.dart';
import 'photo_service.dart';

const _kPaper = Color(0xFFF4E9D4);
const _kBrown = Color(0xFF3A2810);
const _kBrownMid = Color(0xFF7A5830);
const _kBrownLight = Color(0xFFA08060);
const _kBorder = Color(0xFFC8B890);
const _kAccent = Color(0xFF8A7050);
const _kGreen = Color(0xFF2A4A20);
const _kSlotBg = Color(0xFFEDE0C4);

class PhotoSlotWidget extends StatefulWidget {
  final PhotoSlotData slot;
  final String? imagePath;
  final ValueChanged<String> onPhotoAdded;
  // Was missing before — PhotoService.pickAndUploadPhoto() needs a questId
  // to build the storage path ('$userId/$questId/$slotId...'), but nothing
  // upstream of this widget passed one through, and _pickPhoto below
  // wasn't even calling PhotoService, so no photo ever reached Supabase.
  final String questId;

  const PhotoSlotWidget({
    super.key,
    required this.slot,
    required this.imagePath,
    required this.onPhotoAdded,
    required this.questId,
  });

  @override
  State<PhotoSlotWidget> createState() => _PhotoSlotWidgetState();
}

class _PhotoSlotWidgetState extends State<PhotoSlotWidget> {
  bool _hovered = false;
  bool _uploading = false;
  final _photoService = PhotoService();

  Future<void> _pickPhoto() async {
    if (_uploading) return;
    setState(() => _uploading = true);

    // Was: raw ImagePicker.pickImage() storing the local file path only,
    // so nothing was ever uploaded to the 'journal-photos' bucket. Now
    // goes through PhotoService, which uploads and returns the hosted URL.
    final url = await _photoService.pickAndUploadPhoto(
      questId: widget.questId,
      slotId: widget.slot.id,
    );

    if (!mounted) return;
    setState(() => _uploading = false);

    if (url != null) {
      widget.onPhotoAdded(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not upload photo — check your connection and try again.')),
      );
    }
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: _kBrownMid),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, color: _kBrownMid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.imagePath != null && widget.imagePath!.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _pickPhoto,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _hovered && !hasPhoto ? const Color(0xFFE0D4B0) : _kSlotBg,
            border: Border.all(
              color: _hovered ? _kGreen : _kAccent,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _DashedBorderPainter(_hovered)),
              ),
              if (hasPhoto)
                _buildImage(widget.imagePath!)
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '+ ADD\nPHOTO',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 6,
                        color: _hovered ? _kGreen : _kAccent,
                        height: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        widget.slot.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.vt323(
                          fontSize: 13,
                          color: _kBrownMid,
                        ),
                      ),
                    ),
                  ],
                ),
              if (hasPhoto && _hovered && !_uploading)
                Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Text(
                    '▶ CHANGE',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 6,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (_uploading)
                Container(
                  color: Colors.black45,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final bool hovered;
  _DashedBorderPainter(this.hovered);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (hovered ? _kGreen : _kAccent).withAlpha(178)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashLen = 5.0;
    const gapLen = 4.0;

    void drawDashedLine(Offset start, Offset end) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final total = (dx.abs() > dy.abs() ? dx.abs() : dy.abs());
      if (total == 0) return;
      final nx = dx / total;
      final ny = dy / total;

      double pos = 0;
      bool drawing = true;
      while (pos < total) {
        final segLen = drawing ? dashLen : gapLen;
        final next = (pos + segLen).clamp(0.0, total);
        if (drawing) {
          canvas.drawLine(
            Offset(start.dx + nx * pos, start.dy + ny * pos),
            Offset(start.dx + nx * next, start.dy + ny * next),
            paint,
          );
        }
        pos = next;
        drawing = !drawing;
      }
    }

    drawDashedLine(Offset.zero, Offset(size.width, 0));
    drawDashedLine(Offset(size.width, 0), Offset(size.width, size.height));
    drawDashedLine(Offset(size.width, size.height), Offset(0, size.height));
    drawDashedLine(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.hovered != hovered;
}

class JournalPageWidget extends StatelessWidget {
  final JournalPageData page;
  final Map<String, String> photos;
  final ValueChanged<MapEntry<String, String>> onPhotoAdded;
  final int pageNum;
  final bool isLeft;
  final List<String> stickerUrls; // Added to receive bucket stickers directly
  final String questId; // threaded down to each PhotoSlotWidget's upload path

  const JournalPageWidget({
    super.key,
    required this.page,
    required this.photos,
    required this.onPhotoAdded,
    required this.pageNum,
    required this.isLeft,
    this.stickerUrls = const [],
    required this.questId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kPaper,
        border: Border(
          top: const BorderSide(color: _kBorder, width: 3),
          bottom: const BorderSide(color: _kBorder, width: 3),
          left: isLeft ? const BorderSide(color: _kBorder, width: 3) : BorderSide.none,
          right: isLeft ? BorderSide.none : const BorderSide(color: _kBorder, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: _buildCollageGrid()),
            const SizedBox(height: 6),
            // Italic note line - was missing entirely in the newer version.
            Text(
              page.notePlaceholder,
              style: GoogleFonts.vt323(fontSize: 13, color: _kBrownMid, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            _buildStickerRow(pageNum),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          page.title,
          style: GoogleFonts.pressStart2p(fontSize: 7, color: _kBrown),
        ),
        Text(
          page.date,
          style: GoogleFonts.pressStart2p(fontSize: 5, color: _kBrownMid),
        ),
      ],
    );
  }

  Widget _buildCollageGrid() {
    return Column(
      children: page.slots.map((s) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: PhotoSlotWidget(
              slot: s,
              imagePath: photos[s.id],
              onPhotoAdded: (path) => onPhotoAdded(MapEntry(s.id, path)),
              questId: questId,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStickerRow(int num) {
    return Row(
      children: [
        // Per-page emoji stickers (from the mock/backend page data itself) -
        // restored from your original design.
        ...page.stickers.map(
          (s) => Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Text(s, style: const TextStyle(fontSize: 14)),
          ),
        ),
        // Bucket sticker preview thumbnails, if any exist (separate from
        // the page's own stickers - these come from Supabase Storage).
        if (stickerUrls.isNotEmpty)
          ...stickerUrls.take(3).map(
                (url) => Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Image.network(
                    url,
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.star,
                      size: 14,
                      color: _kAccent,
                    ),
                  ),
                ),
              ),
        const Spacer(),
        Text(
          'P.$num',
          style: GoogleFonts.pressStart2p(fontSize: 5, color: _kBrownLight),
        ),
      ],
    );
  }
}