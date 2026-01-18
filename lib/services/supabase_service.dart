import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }
  
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
  
  // Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;
  
  // Get current user ID
  static String? get currentUserId => client.auth.currentUser?.id;
  
  // Get current user email
  static String? get currentUserEmail => client.auth.currentUser?.email;
}
