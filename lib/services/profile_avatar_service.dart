import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'supabase_service.dart';

/// Service for handling profile avatar image operations.
class ProfileAvatarService {
  static const String _bucketName = 'profile-avatars';

  /// Uploads an avatar image for a user profile.
  ///
  /// Returns the public URL on success, null on failure.
  static Future<String?> uploadAvatar(String userId, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Validate image bytes
      if (!_isValidImageBytes(bytes)) {
        if (kDebugMode) {
          debugPrint('Invalid image file');
        }
        return null;
      }

      // Generate unique file path
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final filePath = 'avatars/$fileName';

      // Remove old avatar first (ignore errors)
      await _removeOldAvatars(userId);

      // Upload to Supabase Storage
      await SupabaseService.client.storage
          .from(_bucketName)
          .uploadBinary(filePath, bytes);

      // Get public URL
      final publicUrl = SupabaseService.client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  /// Removes old avatar files for a user.
  static Future<void> _removeOldAvatars(String userId) async {
    try {
      final files = await SupabaseService.client.storage
          .from(_bucketName)
          .list(path: 'avatars');

      final userFiles = files
          .where((f) => f.name.startsWith('${userId}_'))
          .map((f) => 'avatars/${f.name}')
          .toList();

      if (userFiles.isNotEmpty) {
        await SupabaseService.client.storage
            .from(_bucketName)
            .remove(userFiles);
      }
    } catch (e) {
      debugPrint('Error removing old avatars: $e');
    }
  }

  /// Removes the avatar for a user (revert to initials).
  static Future<bool> removeAvatar(String userId, String? currentUrl) async {
    try {
      if (currentUrl != null && currentUrl.contains(_bucketName)) {
        await _removeOldAvatars(userId);
      }
      return true;
    } catch (e) {
      debugPrint('Error removing avatar: $e');
      return false;
    }
  }

  /// Validates image bytes by checking magic numbers.
  static bool _isValidImageBytes(Uint8List bytes) {
    if (bytes.length < 12) return false;

    // Check JPEG magic bytes
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // Check PNG magic bytes
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return true;
    }

    // Check GIF magic bytes
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }

    // Check WebP magic bytes
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    return false;
  }
}
