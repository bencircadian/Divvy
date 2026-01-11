import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/household_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'services/cache_service.dart';
import 'services/deep_link_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await SupabaseService.initialize();
  await CacheService.initialize();
  // Initialize SyncManager to handle connectivity and sync coordination
  SyncManager.instance;
  runApp(const DivvyApp());
}

class DivvyApp extends StatefulWidget {
  const DivvyApp({super.key});

  @override
  State<DivvyApp> createState() => _DivvyAppState();
}

class _DivvyAppState extends State<DivvyApp> {
  GoRouter? _router;
  bool _deepLinkInitialized = false;

  void _initializeDeepLinks(GoRouter router) {
    if (!_deepLinkInitialized && !kIsWeb) {
      _deepLinkInitialized = true;
      DeepLinkService().initialize(router);
    }
  }

  @override
  void dispose() {
    DeepLinkService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HouseholdProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final householdProvider = context.watch<HouseholdProvider>();
          final themeProvider = context.watch<ThemeProvider>();

          _router ??= AppRouter.router(authProvider, householdProvider);
          _initializeDeepLinks(_router!);

          return MaterialApp.router(
            title: 'Divvy',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.effectiveThemeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            routerConfig: _router,
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    // Use DM Sans for the organic theme
    final textTheme = GoogleFonts.dmSansTextTheme(
      brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    // Custom color scheme with new green palette
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primary.withValues(alpha: 0.15),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.primary.withValues(alpha: 0.15),
      onSecondaryContainer: AppColors.primaryDark,
      error: AppColors.error,
      onError: Colors.white,
      surface: isDark ? AppColors.cardDark : AppColors.cardLight,
      onSurface: isDark ? Colors.white : Colors.grey[900]!,
      surfaceContainerHighest: isDark ? AppColors.surfaceDark : Colors.grey[100]!,
      outline: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      shadow: Colors.black,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      useMaterial3: true,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        foregroundColor: isDark ? Colors.white : Colors.grey[900],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: isDark ? const Color(0xFF102219) : Colors.white,
        elevation: isDark ? 8 : 0,
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.primary);
          }
          return IconThemeData(color: isDark ? Colors.grey[400] : Colors.grey[600]);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
        thickness: 1,
      ),
    );
  }
}
