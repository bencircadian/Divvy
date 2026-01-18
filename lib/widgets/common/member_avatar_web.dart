import 'package:flutter/material.dart';

/// Web implementation - just returns fallback for external URLs.
/// External images (like Google profile pics) have CORS issues on web.
/// Only Supabase storage URLs work on web since they have proper CORS headers.
Widget buildWebImage({
  required String url,
  required double size,
  required Widget fallback,
  Key? key,
}) {
  // Check if this is a Supabase storage URL (our own storage has CORS configured)
  if (url.contains('supabase') && url.contains('storage')) {
    // Supabase URLs should work - use NetworkImage
    return Container(
      key: key,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {},
        ),
      ),
    );
  }

  // External URLs (Google, etc.) - just show initials on web
  return fallback;
}
