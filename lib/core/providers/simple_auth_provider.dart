import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_models;

class SimpleAuthProvider extends ChangeNotifier {
  app_models.User? _user;
  bool _isLoading = false;
  String? _error;
  String? _verificationId;
  int? _resendToken;

  // Getters
  app_models.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get verificationId => _verificationId;

  // Mobile authentication methods
  Future<bool> sendOtp({required String phoneNumber}) async {
    _setLoading(true);
    _clearError();

    // Simulate sending OTP
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, you would use Firebase Authentication or similar service
    // For demo purposes, we'll just simulate success
    if (phoneNumber.isNotEmpty && phoneNumber.length >= 10) {
      // Generate a fake verification ID for demo
      _verificationId =
          'demo_verification_id_${DateTime.now().millisecondsSinceEpoch}';
      _setLoading(false);
      return true;
    } else {
      _setError('Please enter a valid phone number');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp({required String otp}) async {
    _setLoading(true);
    _clearError();

    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, you would verify with Firebase or your backend
    // For demo purposes, accept any 6-digit OTP
    if (otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp)) {
      // Create or sign in user
      _user = app_models.User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Farmer User',
        email: '', // Not required for mobile auth
        phoneNumber: '1234567890', // This would be the actual phone number
        preferredLanguage: 'en',
        createdAt: DateTime.now(),
        farmIds: [], // Empty to trigger onboarding
      );
      _setLoading(false);
      return true;
    } else {
      _setError('Please enter a valid 6-digit OTP');
      _setLoading(false);
      return false;
    }
  }

  // Keep existing methods for backward compatibility (but we'll remove email/password UI)
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
    _verificationId = null;
    _resendToken = null;
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
