/// ------------------------------------------------------------
///  1. Create a free project at https://supabase.com
///  2. Project Settings > API  -> copy the URL and the anon key
///  3. Paste them below (or pass with --dart-define, see README)
/// ------------------------------------------------------------
class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ulykagbqznblhmrmvbch.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVseWthZ2Jxem5ibGhtcm12YmNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE2MTgyNDcsImV4cCI6MjEwNzE5NDI0N30.T3uDi-q3lu2sV8KJL5EG1OXiUGLaiovJSv1jlsfVSAI',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Bookable hours: 8:00 AM (8) until 12:00 AM midnight (24).
  static const int openHour = 8;
  static const int closeHour = 24;
  static int get totalSlots => closeHour - openHour;

  static const String courtKolej = 'Court Kolej';
  static const String courtKampus = 'Court Kampus';
  static const List<String> courts = [courtKolej, courtKampus];

  static const List<String> sports = [
    'Basketball',
    'Netball',
    'Handball',
    'Futsal',
    'Volleyball',
    'Badminton',
    'Sepak Takraw',
    'Other',
  ];
}
