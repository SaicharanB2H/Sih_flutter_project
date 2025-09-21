import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_models;

class SimpleAuthProvider extends ChangeNotifier {
  app_models.User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  app_models.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Simple validation - accept any email/password combination
    if (email.isNotEmpty && password.isNotEmpty) {
      _user = app_models.User(
        id: 'user123',
        name: 'Demo Farmer',
        email: email,
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
        farmIds: [], // Empty to trigger onboarding
      );
      _setLoading(false);
      return true;
    } else {
      _setError('Please enter valid credentials');
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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
      _user = app_models.User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        preferredLanguage: preferredLanguage,
        createdAt: DateTime.now(),
        farmIds: [], // Empty to trigger onboarding
      );
      _setLoading(false);
      return true;
    } else {
      _setError('Please fill all required fields');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
    _setLoading(false);
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    await Future.delayed(const Duration(seconds: 1));

    if (email.isNotEmpty) {
      _setLoading(false);
      return true;
    } else {
      _setError('Please enter a valid email');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateUserData(app_models.User updatedUser) async {
    _setLoading(true);

    await Future.delayed(const Duration(seconds: 1));

    _user = updatedUser;
    _setLoading(false);
    return true;
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

  // Method to simulate completing onboarding
  void completeOnboarding() {
    if (_user != null) {
      _user = _user!.copyWith(farmIds: ['farm123']);
      notifyListeners();
    }
  }
}
