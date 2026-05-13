import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  int _unreadCount = 0;
  Timer? _pollTimer;

  int get unreadCount => _unreadCount;

  void startPolling() {
    _pollTimer?.cancel();
    _fetchUnreadCount();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _fetchUnreadCount();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
  }

  Future<void> _fetchUnreadCount() async {
    final count = await _apiService.fetchGlobalUnreadCount();
    if (count != null && count != _unreadCount) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
