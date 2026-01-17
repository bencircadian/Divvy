import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../config/app_theme.dart';

/// A feature tour screen shown on first app launch
class FeatureTourScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const FeatureTourScreen({super.key, required this.onComplete});

  @override
  State<FeatureTourScreen> createState() => _FeatureTourScreenState();

  /// Check if this is the user's first launch
  static Future<bool> isFirstLaunch() async {
    final box = await Hive.openBox('app_preferences');
    return box.get('has_seen_tour', defaultValue: true);
  }

  /// Mark the tour as seen
  static Future<void> markTourSeen() async {
    final box = await Hive.openBox('app_preferences');
    await box.put('has_seen_tour', false);
  }
}

class _FeatureTourScreenState extends State<FeatureTourScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _TourPage(
      icon: Icons.home_rounded,
      title: 'Welcome to Divvy',
      description: 'The smart way to manage household tasks with your family or roommates.',
      gradient: [AppColors.primary, AppColors.primaryDark],
    ),
    _TourPage(
      icon: Icons.checklist_rounded,
      title: 'Track Tasks Together',
      description: 'Create, assign, and complete tasks. See who did what and when.',
      gradient: [AppColors.kitchen, Color(0xFFFF6B4A)],
    ),
    _TourPage(
      icon: Icons.local_fire_department_rounded,
      title: 'Build Your Streak',
      description: 'Complete tasks daily to build your streak and see your household stats.',
      gradient: [AppColors.success, Color(0xFF2DD4A0)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTour();
    }
  }

  void _completeTour() async {
    await FeatureTourScreen.markTourSeen();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeTour,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _pages[index],
              ),
            ),
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  const _TourPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon in gradient circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : Colors.grey[900],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? AppColors.textSecondary : Colors.grey[600],
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
