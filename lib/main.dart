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

class CourtApp extends StatelessWidget {
  const CourtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JSP Court Booking · UiTM Kuala Terengganu',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: ThemeMode.dark,
      home: AppConfig.isConfigured
          ? const _AuthGate()
          : const SetupScreen(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

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
              )
            : const HomeShell();
      },
    );
  }
}
