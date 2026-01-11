/// Supabase configuration using compile-time environment variables
///
/// To build with custom values, use --dart-define flags:
/// ```
/// flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
/// ```
///
/// For production builds:
/// ```
/// flutter build web --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
/// ```
class SupabaseConfig {
  /// Supabase project URL (loaded from environment or default)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://njdkpymsjjlowpynfinr.supabase.co',
  );

  /// Supabase anonymous key (loaded from environment or default)
  /// Note: The anon key is safe for client-side use as security is enforced via RLS policies
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5qZGtweW1zampsb3dweW5maW5yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0ODA3OTEsImV4cCI6MjA4MzA1Njc5MX0.jkN_r7wWgJ3PGgOTauai7Cx-PtGxcCD4xKuWfrfxZdA',
  );

  /// Check if using default (development) configuration
  static bool get isDefaultConfig =>
      url == 'https://njdkpymsjjlowpynfinr.supabase.co';
}
