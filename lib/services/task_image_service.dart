import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'supabase_service.dart';

/// Service for handling task cover image operations.
///
/// Extracted from TaskProvider to improve separation of concerns.
class TaskImageService {
  static const String _bucketName = 'task-covers';

  /// Uploads a cover image for a task.
  ///
  /// Returns the file path on success, null on failure.
  static Future<String?> uploadCoverImage(String taskId, XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Validate image bytes
      if (!_isValidImageBytes(bytes)) {
        debugPrint('Invalid image file');
        return null;
      }

      // Generate unique file path
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${taskId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final filePath = 'covers/$fileName';

      // Upload to Supabase Storage
      await SupabaseService.client.storage
          .from(_bucketName)
          .uploadBinary(filePath, bytes);

      // Update task with cover image path
      await SupabaseService.client
          .from('tasks')
          .update({'cover_image_url': filePath})
          .eq('id', taskId);

      return filePath;
    } catch (e) {
      debugPrint('Error uploading cover image: $e');
      return null;
    }
  }

  /// Gets a signed URL for a cover image path.
  ///
  /// Returns a time-limited URL for secure access.
  static Future<String?> getSignedCoverUrl(String filePath) async {
    try {
      final response = await SupabaseService.client.storage
          .from(_bucketName)
          .createSignedUrl(filePath, 3600); // 1 hour expiry
      return response;
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      return null;
    }
  }

  /// Removes a cover image from a task.
  static Future<bool> removeCoverImage(String taskId, String? currentPath) async {
    try {
      // Remove from storage if path exists
      if (currentPath != null && currentPath.isNotEmpty && !currentPath.startsWith('http')) {
        try {
          await SupabaseService.client.storage
              .from(_bucketName)
              .remove([currentPath]);
        } catch (e) {
          debugPrint('Error removing file from storage: $e');
        }
      }

      // Update task to remove cover image reference
      await SupabaseService.client
          .from('tasks')
          .update({'cover_image_url': null})
          .eq('id', taskId);

      return true;
    } catch (e) {
      debugPrint('Error removing cover image: $e');
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
