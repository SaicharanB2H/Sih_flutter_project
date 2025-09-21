import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../services/auth_service.dart';
import '../models/user.dart' as app_models;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  app_models.User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  app_models.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges.listen((auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getCurrentUserData();
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      _user = result.user;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error!);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String preferredLanguage = 'en',
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
      phoneNumber: phoneNumber,
      preferredLanguage: preferredLanguage,
    );

    if (result.isSuccess) {
      _user = result.user;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error!);
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _user = null;
    _setLoading(false);
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    final result = await _authService.sendPasswordResetEmail(email);

    if (result.isSuccess) {
      _setLoading(false);
      return true;
    } else {
      _setError(result.error!);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateUserData(app_models.User updatedUser) async {
    _setLoading(true);

    final success = await _authService.updateUserData(updatedUser);

    if (success) {
      _user = updatedUser;
    }

    _setLoading(false);
    return success;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
