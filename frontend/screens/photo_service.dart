import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoService {
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  /// Picks an image and uploads it to Supabase bucket
  Future<String?> pickAndUploadPhoto({
    required String questId,
    required String slotId,
  }) async {
    try {
      // 1. Pick image from device gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress to save bandwidth
      );

      if (image == null) return null; // User canceled picking

      final file = File(image.path);
      final userId = _supabase.auth.currentUser?.id ?? 'guest_user';
      final fileExt = image.path.split('.').last;
      
      // Construct a unique path inside the bucket
      final filePath = '$userId/$questId/${slotId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // 2. Upload to Supabase bucket named 'journal-photos'
      await _supabase.storage.from('journal-photos').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // 3. Get the public URL to render in Flutter
      final String publicUrl = _supabase.storage
          .from('journal-photos')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }
}