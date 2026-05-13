import 'package:flutter/material.dart';

/// Manages the active bottom-nav tab index so any screen deep in the tree
/// can trigger a tab switch without needing callbacks passed down the tree.
class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void goToTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }
}
