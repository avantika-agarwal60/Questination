import 'package:flutter/material.dart';

// 1. Template: Single Big Photo + Caption
class StandardPhotoTemplate extends StatelessWidget {
  final String title;
  final String description;
  final String slotId;
  final String? photoPath;
  final Function(String slotId) onSlotTap;

  const StandardPhotoTemplate({
    super.key,
    required this.title,
    required this.description,
    required this.slotId,
    this.photoPath,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onSlotTap(slotId),
          child: Container(
            height: 180,
            width: double.infinity,
            color: Colors.grey[300],
            child: photoPath != null
                ? Image.network(photoPath!, fit: BoxFit.cover)
                : const Icon(Icons.add_a_photo),
          ),
        ),
        const SizedBox(height: 8),
        Text(description),
      ],
    );
  }
}

// 2. Template: 2-Grid Photos
class GridTwoPhotoTemplate extends StatelessWidget {
  final List<String> slotIds;
  final Map<String, String> photos;
  final Function(String slotId) onSlotTap;

  const GridTwoPhotoTemplate({
    super.key,
    required this.slotIds,
    required this.photos,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: slotIds.map((id) {
        final path = photos[id];
        return Expanded(
          child: GestureDetector(
            onTap: () => onSlotTap(id),
            child: Container(
              height: 120,
              margin: const EdgeInsets.all(4),
              color: Colors.grey[200],
              child: path != null
                  ? Image.network(path, fit: BoxFit.cover)
                  : const Icon(Icons.add_photo_alternate),
            ),
          ),
        );
      }).toList(),
    );
  }
}