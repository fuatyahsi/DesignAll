import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// Supabase Service provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// Auth state provider — oturum değişikliklerini dinler
final authStateProvider = StreamProvider<AuthState>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.authStateChanges;
});

// Mevcut kullanıcı provider
final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

// Auth işlemleri için StateNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthUiState>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return AuthNotifier(service);
});

// Auth UI durumu
class AuthUiState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const AuthUiState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AuthUiState copyWith({bool? isLoading, String? errorMessage, bool? isSuccess}) {
    return AuthUiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthUiState> {
  final SupabaseService _service;

  AuthNotifier(this._service) : super(const AuthUiState());

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.signIn(email, password);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _localizeError(e.message));
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Bir hata oluştu. Tekrar deneyin.');
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.signUp(email, password, fullName);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _localizeError(e.message));
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Bir hata oluştu. Tekrar deneyin.');
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _service.resetPassword(email);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'E-posta gönderilemedi.');
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthUiState();
  }

  void resetState() {
    state = const AuthUiState();
  }

  String _localizeError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (message.contains('Email not confirmed')) {
      return 'E-postanızı henüz doğrulamadınız.';
    }
    if (message.contains('User already registered')) {
      return 'Bu e-posta zaten kayıtlı.';
    }
    if (message.contains('Password should be at least')) {
      return 'Şifre en az 6 karakter olmalı.';
    }
    return message;
  }
}
