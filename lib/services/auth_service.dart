import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Google Sign In (Native)
  Future<bool> signInWithGoogle() async {
    try {
      // Sign in with Google using Supabase Auth
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.teammate://login-callback/',
      );

      // 登入成功後設置 OneSignal 用戶 ID
      if (response && userId != null) {
        await _notificationService.setUserId(userId!);
      }

      return response;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign in with Google (Web)
  Future<bool> signInWithGoogleWeb() async {
    try {
      // For web, don't specify redirectTo - Supabase will handle it automatically
      // The session will be stored in localStorage and persisted across page refreshes
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );

      // 登入成功後設置 OneSignal 用戶 ID
      if (response && userId != null) {
        await _notificationService.setUserId(userId!);
      }

      return response;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      // 登出時清除 OneSignal 用戶 ID
      await _notificationService.logout();
      
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Get user ID
  String? get userId => currentUser?.id;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user metadata
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  // Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response;
    } catch (e) {
      print('Error refreshing session: $e');
      rethrow;
    }
  }
}
