import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final appUserProvider = StateNotifierProvider<AppUserNotifier, AsyncValue<AppUser?>>((ref) {
  return AppUserNotifier(ref.watch(authServiceProvider));
});

class AppUserNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthService _authService;

  AppUserNotifier(this._authService) : super(const AsyncValue.data(null));

  Future<void> signInWithEmail({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmail(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  void setUser(AppUser user) {
    state = AsyncValue.data(user);
  }

  void clearError() {
    if (state is AsyncError) {
      state = const AsyncValue.data(null);
    }
  }
}
