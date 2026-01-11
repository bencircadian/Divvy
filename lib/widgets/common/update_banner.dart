import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../services/version_service.dart';

/// A banner that shows when a new app version is available.
class UpdateBanner extends StatefulWidget {
  final Widget child;

  const UpdateBanner({
    super.key,
    required this.child,
  });

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  final _versionService = VersionService();
  StreamSubscription<bool>? _subscription;
  bool _showBanner = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _versionService.startChecking();
      _subscription = _versionService.updateAvailable.listen((hasUpdate) {
        if (hasUpdate && mounted && !_dismissed) {
          setState(() => _showBanner = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _dismiss() {
    setState(() {
      _showBanner = false;
      _dismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDarkMode : AppColors.primary;

    return Column(
      children: [
        // Update banner
        Material(
          color: primaryColor,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.system_update,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'A new version is available',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Trigger reload via JavaScript
                      _reloadPage();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Reload'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // App content
        Expanded(child: widget.child),
      ],
    );
  }

  void _reloadPage() {
    if (kIsWeb) {
      // Use universal_html or just trigger via JS
      // For simplicity, we'll use a workaround
      _versionService.reloadApp();
      // Show a snackbar prompting manual reload if automatic doesn't work
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please refresh your browser to get the latest version'),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}
