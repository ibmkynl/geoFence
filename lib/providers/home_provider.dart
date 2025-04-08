import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geo_fence/screens/dashboard_screen/home_tabs/summary_screen.dart';

import '../screens/dashboard_screen/home_tabs/main_screen.dart';

enum AppScreen { main, summary }

class HomeProvider with ChangeNotifier {
  final _screens = [const MainScreen(), const SummaryScreen()];

  int _currentIndex = 0;

  Future<void> switchToIndex(int index) async {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> switchToScreen(AppScreen screen) async {
    _currentIndex = AppScreen.values.indexOf(screen);
    notifyListeners();
  }

  void reset() {
    _currentIndex = AppScreen.main.index;
    notifyListeners();
  }

  int get currentIndex => _currentIndex;

  Widget get selectedScreen => _screens.elementAt(_currentIndex);
}
