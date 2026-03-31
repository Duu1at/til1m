class SupabaseConstants {
  SupabaseConstants._();

  //h your actual Supabase credentials from .env or --dart-define
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  // Table names
  static const String tableWords = 'words';
  static const String tableWordTranslations = 'word_translations';
  static const String tableWordExamples = 'word_examples';
  static const String tableUserSettings = 'user_settings';
  static const String tableUserWordProgress = 'user_word_progress';
  static const String tableUserFavorites = 'user_favorites';

  // Storage buckets
  static const String bucketAudio = 'audio';
  static const String bucketImages = 'images';
}
