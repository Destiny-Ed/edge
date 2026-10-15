import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between dark and light theme'),
            value: settings.isDark,
            activeColor: const Color(0xFF00C853),
            onChanged: (_) => settings.toggleTheme(),
          ),
          const Divider(height: 32),
          _sectionTitle('Notifications'),
          SwitchListTile(
            title: const Text('Daily Predictions'),
            subtitle: const Text(
                'Remind me every morning when new tips are ready'),
            value: settings.dailyNotifications,
            activeColor: const Color(0xFF00C853),
            onChanged: (v) => settings.setDailyNotifications(v),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Note: Full local notification scheduling can be added later with flutter_local_notifications.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          const Divider(height: 32),
          _sectionTitle('About'),
          const ListTile(
            title: Text('Edge'),
            subtitle: Text('Smart picks. Clear edge.\nVersion 1.2.0'),
          ),
          const ListTile(
            title: Text('Data Source'),
            subtitle: Text('API-Sports (api-football.com)'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
