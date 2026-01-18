import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  AuthStatus _status = AuthStatus.initial;
  UserProfile? _userProfile;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSubscription;
  
  AuthProvider() {
    _initAuth();
  }
  
  // Getters
  AuthStatus get status => _status;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  int get creditsRemaining => _userProfile?.creditsRemaining ?? 0;
  
  // Initialize auth state listener
  void _initAuth() {
    _authSubscription = _authService.authStateChanges.listen((state) async {
      if (state.session != null) {
        await _loadUserProfile();
        _status = AuthStatus.authenticated;
      } else {
        _userProfile = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
    
    // Check initial auth state
    _checkInitialAuth();
  }
  
  Future<void> _checkInitialAuth() async {
    if (_authService.isSignedIn) {
      await _loadUserProfile();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await _authService.getCurrentProfile();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }
  
  // Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _loadUserProfile();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }
  
  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _authService.signIn(
        email: email,
        password: password,
      );
      await _loadUserProfile();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _userProfile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send reset email';
      notifyListeners();
      return false;
    }
  }
  
  // Refresh profile (e.g., after credit deduction)
  Future<void> refreshProfile() async {
    await _loadUserProfile();
    notifyListeners();
  }
  
  // Deduct credits
  Future<bool> deductCredits(int amount) async {
    if (_userProfile == null) return false;
    if (_userProfile!.creditsRemaining < amount) return false;
    
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) return false;
      
      await SupabaseService.client.from('profiles').update({
        'credits_remaining': _userProfile!.creditsRemaining - amount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      
      // Record transaction
      await SupabaseService.client.from('credit_transactions').insert({
        'user_id': userId,
        'amount': -amount,
        'transaction_type': 'used',
        'description': 'Listing generation',
      });
      
      await refreshProfile();
      return true;
    } catch (e) {
      debugPrint('Error deducting credits: $e');
      return false;
    }
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
