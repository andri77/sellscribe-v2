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
    String? firstName,
    String? lastName,
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
        firstName: firstName,
        lastName: lastName,
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
    final userEmail = SupabaseService.currentUserEmail;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle to handle 0 rows

      if (response != null) {
        print('Loaded profile: $response'); // Debug log
        return UserProfile.fromJson(response);
      }

      // Profile doesn't exist, create one
      print('Profile not found, creating new profile'); // Debug log
      await _createProfile(
        userId: userId,
        email: userEmail ?? '',
      );

      // Fetch the newly created profile
      final newResponse = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(newResponse);
    } catch (e) {
      print('Error loading profile: $e'); // Debug log
      return null;
    }
  }
  
  // Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? firstName,
    String? lastName,
    String? mobile,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Helper to add non-empty values
    void addIfNotEmpty(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        updates[key] = value;
      }
    }

    addIfNotEmpty('display_name', displayName);
    addIfNotEmpty('first_name', firstName);
    addIfNotEmpty('last_name', lastName);
    addIfNotEmpty('mobile', mobile);
    addIfNotEmpty('address', address);
    addIfNotEmpty('city', city);
    addIfNotEmpty('state', state);
    addIfNotEmpty('zip_code', zipCode);
    addIfNotEmpty('country', country);

    // Use upsert to create profile if it doesn't exist
    final data = {
      'id': userId,
      'email': SupabaseService.currentUserEmail ?? '',
      'credits_remaining': 5, // Default credits for new users
      ...updates,
    };

    print('Saving profile data: $data'); // Debug log

    await _client.from('profiles').upsert(
      data,
      onConflict: 'id', // Update if id exists
    );

    print('Profile saved successfully'); // Debug log
  }
  
  // Create profile for new user
  Future<void> _createProfile({
    required String userId,
    required String email,
    String? displayName,
    String? firstName,
    String? lastName,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'email': email,
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
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
