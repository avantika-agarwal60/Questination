import 'package:flutter/material.dart';

class StandardPhotoTemplate extends StatelessWidget {
  final String title;
  final String description;
  final String slotId;
  final String? photoPath;
  final ValueChanged<String> onSlotTap;

  const StandardPhotoTemplate({
    super.key,
    required this.title,
    required this.description,
    required this.slotId,
    required this.onSlotTap,
    this.photoPath,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => onSlotTap(slotId),
            child: Container(
              height: 180,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: photoPath == null
                  ? const Icon(Icons.add_a_photo)
                  : Image.network(photoPath!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(description),
        ],
      );
}

class GridTwoPhotoTemplate extends StatelessWidget {
  final List<String> slotIds;
  final Map<String, String> photos;
  final ValueChanged<String> onSlotTap;

  const GridTwoPhotoTemplate({
    super.key,
    required this.slotIds,
    required this.photos,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: slotIds.map((id) {
          final path = photos[id];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSlotTap(id),
              child: Container(
                height: 120,
                margin: const EdgeInsets.all(4),
                color: Colors.grey.shade200,
                child: path == null
                    ? const Icon(Icons.add_photo_alternate)
                    : Image.network(path, fit: BoxFit.cover),
              ),
            ),
          );
        }).toList(),
      );
}
