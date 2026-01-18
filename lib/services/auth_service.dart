import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../config/app_config.dart';
import 'supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;
  
  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    
    if (response.user != null) {
      // Create profile with default credits
      await _createProfile(
        userId: response.user!.id,
        email: email,
        displayName: displayName,
      );
    }
    
    return response;
  }
  
  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
  
  // Get current user profile
  Future<UserProfile?> getCurrentProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;
    
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    
    return UserProfile.fromJson(response);
  }
  
  // Update user profile
  Future<void> updateProfile({
    String? displayName,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;
    
    await _client.from('profiles').update({
      if (displayName != null) 'display_name': displayName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
  
  // Create profile for new user
  Future<void> _createProfile({
    required String userId,
    required String email,
    String? displayName,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'email': email,
      'display_name': displayName,
      'credits_remaining': AppConfig.defaultCredits,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  
  // Get current session
  Session? get currentSession => _client.auth.currentSession;
  
  // Check if user is signed in
  bool get isSignedIn => _client.auth.currentUser != null;
}
