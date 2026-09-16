/// Application configuration for ChessGo
class AppConfig {
  AppConfig._();

  /// Supabase project URL - Replace with your project URL from Supabase dashboard
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase anon public API key - Replace with your anon key from Supabase dashboard
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// True if Supabase credentials have been configured
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('YOUR_SUPABASE');

  /// Supported time controls in seconds
  static const List<int> timeControls = [
    180, // 3 minutes (Blitz)
    300, // 5 minutes (Blitz)
    600, // 10 minutes (Rapid)
  ];

  static const int defaultTimeControl = 300; // 5 minutes
}
