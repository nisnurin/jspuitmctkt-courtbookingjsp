import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

/// Shown only until the Supabase URL / key are filled in lib/config.dart.
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: NeonCard(
                glow: C.orange,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.settings_suggest_rounded, size: 40, color: C.orange),
                  const SizedBox(height: 12),
                  const Text('Almost there!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect Supabase to start booking:\n\n'
                    '1. Run supabase/schema.sql in the Supabase SQL Editor.\n'
                    '2. Open lib/config.dart and paste your Project URL and anon key.\n'
                    '3. Restart the app.',
                    style: TextStyle(color: C.muted, height: 1.5),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
