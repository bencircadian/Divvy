import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms.
/// Returns a simple widget that just shows the fallback.
Widget buildWebImage({
  required String url,
  required double size,
  required Widget fallback,
  Key? key,
}) {
  // On non-web platforms, we can use NetworkImage directly
  // This stub just returns the fallback - the actual NetworkImage
  // logic is handled in the main MemberAvatar widget
  return fallback;
}
