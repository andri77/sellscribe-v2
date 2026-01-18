import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  static const String appName = 'SellScribe';
  static const String appVersion = '1.0.0';
  
  // Free tier limits
  static const int defaultCredits = 5;
  static const int maxImagesPerListing = 5;
  
  // AI settings
  static const String aiModel = 'gpt-4o';
  static const int maxTokens = 1500;
  
  // Mock mode - set to true to use mock AI responses
  static bool get useMockAi => openaiApiKey.isEmpty;
  
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }
}
