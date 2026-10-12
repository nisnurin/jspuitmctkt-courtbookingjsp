import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true, _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: _email.text.trim(), password: _pass.text);
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _hero({bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: C.orange.o(0.6)),
            color: C.orange.o(0.1),
          ),
          child: const Text('JSP · UiTM KUALA TERENGGANU',
              style: TextStyle(color: C.orange, fontSize: 11, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
        ),
        SizedBox(height: compact ? 14 : 24),
        Text('BOOK THE\nCOURT.',
            style: TextStyle(fontSize: compact ? 38 : 60, height: 1.05, fontWeight: FontWeight.w800)),
        Text('OWN THE GAME.',
            style: TextStyle(
                fontSize: compact ? 38 : 60,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: C.orange,
                shadows: [Shadow(color: C.orange.o(0.55), blurRadius: 24)])),
        SizedBox(height: compact ? 10 : 20),
        const Text('Court Kolej & Court Kampus booking system for\nJawatankuasa Sukan Pelajar.',
            style: TextStyle(color: C.muted, height: 1.5)),
      ],
    );
  }

  Widget _formCard() {
    return NeonCard(
      glow: C.orange,
      padding: const EdgeInsets.all(26),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('Welcome back', eyebrow: 'JSP login'),
            const SizedBox(height: 4),
            const Text('Sign in to record and manage court bookings.',
                style: TextStyle(color: C.muted, fontSize: 13)),
            const SizedBox(height: 22),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded)),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Enter a valid email address' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass,
              obscureText: _hide,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _hide ? 'Show password' : 'Hide password',
                  icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                  label: 'Sign in', icon: Icons.arrow_forward_rounded, loading: _busy, onPressed: _submit),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 900;
            if (wide) {
              return Row(children: [
                Expanded(child: Padding(padding: const EdgeInsets.all(64), child: _hero())),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(padding: const EdgeInsets.all(24), child: _formCard()),
                    ),
                  ),
                ),
              ]);
            }
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _hero(compact: true),
                    const SizedBox(height: 28),
                    _formCard(),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
