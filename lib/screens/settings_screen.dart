import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white54 : Colors.black54;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Appearance', muted),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Switch between dark and light theme'),
            value: settings.isDark,
            activeColor: const Color(0xFF00C853),
            onChanged: (_) => settings.toggleTheme(),
          ),
          const Divider(height: 32),
          _sectionTitle('Notifications', muted),
          SwitchListTile(
            title: const Text('Daily Predictions'),
            subtitle: const Text(
              'Get a reminder every morning at 7:00 AM',
            ),
            value: settings.dailyNotifications,
            activeColor: const Color(0xFF00C853),
            onChanged: (v) async {
              if (v) {
                // Ask for permission first on iOS/Android
                final granted = await NotificationService.requestPermissions();
                if (!granted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notification permission denied. Enable it in system settings.',
                      ),
                    ),
                  );
                }
              }
              await settings.setDailyNotifications(v);
            },
          ),
          ListTile(
            title: const Text('Test notification'),
            subtitle: const Text('Send a test notification now'),
            trailing: const Icon(Icons.notifications_active_outlined),
            onTap: () async {
              await NotificationService.showTest();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent')),
                );
              }
            },
          ),
          const Divider(height: 32),
          _sectionTitle('About', muted),
          const ListTile(
            title: Text('Edge'),
            subtitle: Text('Smart picks. Clear edge.\nVersion 1.2.1'),
          ),
          const ListTile(
            title: Text('Data Source'),
            subtitle: Text('API-Sports (api-football.com)'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
