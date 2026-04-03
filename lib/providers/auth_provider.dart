import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<String?> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmail(email, password);
      // Check verification
      if (_authService.currentUser != null && !_authService.currentUser!.emailVerified) {
        await _authService.signOut();
        return 'Email not verified. Please check your inbox.';
      }
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _authService.registerWithEmail(email, password, name);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
