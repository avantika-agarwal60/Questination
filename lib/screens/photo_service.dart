import 'package:image_picker/image_picker.dart';

import '../api_service.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUploadPhoto({
    required String questId,
    required String slotId,
  }) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (image == null) return null;

    final mimeType = image.mimeType ?? _mimeTypeFromName(image.name);
    final result = await ApiService.createJournalEntry(
      questId: questId,
      photoBytes: await image.readAsBytes(),
      fileName: image.name,
      contentType: mimeType,
      caption: slotId,
    );
    final urls = result['photo_urls'];
    if (urls is List && urls.isNotEmpty) return urls.first.toString();
    throw const FormatException('Journal upload returned no photo URL.');
  }

  String _mimeTypeFromName(String name) {
    final extension = name.split('.').last.toLowerCase();
    if (extension == 'png') return 'image/png';
    if (extension == 'webp') return 'image/webp';
    return 'image/jpeg';
  }
}
