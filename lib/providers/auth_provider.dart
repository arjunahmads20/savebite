import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentUser => _currentUser;
  int? get currentUserId => _currentUser?['id'] as int?;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _authService.getToken();
    _isAuthenticated = token != null;
    if (_isAuthenticated) {
      _currentUser = await _apiService.fetchCurrentUser();
      if (_currentUser == null) {
        // Token might be invalid or expired
        _isAuthenticated = false;
        await _authService.logout();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    notifyListeners();

    final error = await _authService.login(usernameOrEmail, password);
    
    if (error == null) {
      _isAuthenticated = true;
      _currentUser = await _apiService.fetchCurrentUser();
    }
    
    _isLoading = false;
    notifyListeners();
    
    return error;
  }

  Future<String?> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    final error = await _authService.register(userData);
    
    _isLoading = false;
    notifyListeners();
    
    return error;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
