/// Application configuration for ChessGo
class AppConfig {
  AppConfig._();

  /// Supabase project URL - Replace with your project URL from Supabase dashboard
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://icytgkdtobrbdzpmrnsm.supabase.co',
  );

  /// Supabase anon public API key - Replace with your anon key from Supabase dashboard
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImljeXRna2R0b2JyYmR6cG1ybnNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1NTgyODMsImV4cCI6MjEwNTEzNDI4M30.d-DE7B2z7OyuWXDeu6iW95AC-ymQeVWiWAww5GjxNRs',
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
