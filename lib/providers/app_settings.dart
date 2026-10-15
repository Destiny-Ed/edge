import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool isDark = true;
  bool dailyNotifications = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool('isDark') ?? true;
    dailyNotifications = prefs.getBool('dailyNotifications') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDark = !isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    notifyListeners();
  }

  Future<void> setDailyNotifications(bool value) async {
    dailyNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyNotifications', value);
    notifyListeners();
    // Note: Actual local notification scheduling can be added later with flutter_local_notifications
  }
}
