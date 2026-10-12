import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/public_timetable.dart';
import 'screens/setup_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const CourtApp());
}

class CourtApp extends StatefulWidget {
  const CourtApp({super.key});

  @override
  State<CourtApp> createState() => _CourtAppState();
}

class _CourtAppState extends State<CourtApp> {
  ThemeMode _mode = ThemeMode.dark;

  void _toggleTheme() => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSP Court Booking · UiTM Kuala Terengganu',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(light: true),
      darkTheme: buildTheme(),
      themeMode: _mode,
      home: AppConfig.isConfigured
          ? _AuthGate(onToggleTheme: _toggleTheme, isDark: _mode == ThemeMode.dark)
          : const SetupScreen(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const _AuthGate({required this.onToggleTheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snap) {
        final session = snap.data?.session ?? auth.currentSession;
        return session == null
            ? PublicTimetable(
                onLogin: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                onToggleTheme: onToggleTheme,
                isDark: isDark,
              )
            : HomeShell(onToggleTheme: onToggleTheme, isDark: isDark);
      },
    );
  }
}
