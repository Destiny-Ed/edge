import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/app_settings.dart';
import 'providers/picks_provider.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await NotificationService.init();

  final settings = AppSettings();
  await settings.load();

  // Re-apply schedule if user already enabled it
  if (settings.dailyNotifications) {
    await NotificationService.scheduleDaily7Am();
  }

  final picks = PicksProvider();
  await picks.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: picks),
      ],
      child: const EdgeApp(),
    ),
  );
}

class EdgeApp extends StatelessWidget {
  const EdgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();

    return MaterialApp(
      title: 'Edge',
      debugShowCheckedModeBanner: false,
      themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const MainShell(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F6F8),
      primaryColor: const Color(0xFF00C853),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: const Color(0xFF00C853),
        onPrimary: Colors.black,
        secondary: const Color(0xFF2979FF),
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: isDark ? const Color(0xFF1A1D23) : Colors.white,
        onSurface: isDark ? Colors.white : Colors.black87,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF14161A) : Colors.white,
        selectedItemColor: const Color(0xFF00C853),
        unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1D23) : Colors.white,
        modalBackgroundColor: isDark ? const Color(0xFF1A1D23) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      useMaterial3: true,
    );
  }
}
