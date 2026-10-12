import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'book_screen.dart';
import 'dashboard_screen.dart';
import 'timetable_screen.dart';

class HomeShell extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDark;
  const HomeShell({super.key, this.onToggleTheme, this.isDark = true});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  Key _bookKey = UniqueKey();
  String? _court;
  DateTime? _date;
  int? _hour;

  static const _items = [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.add_circle_rounded, 'New booking'),
    (Icons.grid_view_rounded, 'Timetable'),
  ];

  void _openBook([String? court, DateTime? date, int? hour]) {
    setState(() {
      _court = court;
      _date = date;
      _hour = hour;
      _bookKey = UniqueKey(); // rebuild with the new prefill
      _index = 1;
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok == true) await Supabase.instance.client.auth.signOut();
  }

  Widget get _page {
    switch (_index) {
      case 1:
        return BookScreen(
            key: _bookKey, initialCourt: _court, initialDate: _date, initialHour: _hour);
      case 2:
        return TimetableScreen(onBook: _openBook);
      default:
        return DashboardScreen(onBook: _openBook);
    }
  }

  Widget _logo() => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: C.orange,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: C.orange.o(0.5), blurRadius: 18)],
          ),
          child: const Icon(Icons.sports_basketball_rounded, color: C.onAccent),
        ),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('JSP COURTS', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          Text('UiTM Kuala Terengganu', style: TextStyle(fontSize: 11, color: C.muted)),
        ]),
      ]);

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    if (isDesktop(context)) {
      return Scaffold(
        body: GridBackground(
          child: Row(children: [
            Container(
              width: 264,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: C.surface.o(0.85),
                border: const Border(right: BorderSide(color: C.border)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _logo(),
                const SizedBox(height: 32),
                for (var i = 0; i < _items.length; i++) _navTile(i),
                const Spacer(),
                const Divider(),
                const SizedBox(height: 8),
                Text(email,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: C.muted)),
                const SizedBox(height: 8),
                if (widget.onToggleTheme != null) GhostButton(label: widget.isDark ? 'Light mode' : 'Dark mode', icon: widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: C.muted, onPressed: widget.onToggleTheme),
                SizedBox(
                    width: double.infinity,
                    child: GhostButton(
                        label: 'Sign out', icon: Icons.logout_rounded, color: C.muted, onPressed: _logout)),
              ]),
            ),
            Expanded(child: _page),
          ]),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.surface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: _logo(),
        actions: [
          if (widget.onToggleTheme != null) IconButton(tooltip: widget.isDark ? 'Light mode' : 'Dark mode', onPressed: widget.onToggleTheme, icon: Icon(widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded)),
          IconButton(tooltip: 'Sign out', onPressed: _logout, icon: const Icon(Icons.logout_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      body: GridBackground(child: _page),
      bottomNavigationBar: NavigationBar(
        backgroundColor: C.surface,
        indicatorColor: C.orange.o(0.2),
        selectedIndex: _index,
        onDestinationSelected: (i) => i == 1 ? _openBook() : setState(() => _index = i),
        destinations: [
          for (final it in _items)
            NavigationDestination(
              icon: Icon(it.$1, color: C.muted),
              selectedIcon: Icon(it.$1, color: C.orange),
              label: it.$2,
            ),
        ],
      ),
    );
  }

  Widget _navTile(int i) {
    final sel = _index == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: sel,
        label: _items[i].$2,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => i == 1 ? _openBook() : setState(() => _index = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: sel ? C.orange.o(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? C.orange.o(0.7) : Colors.transparent),
            ),
            child: Row(children: [
              Icon(_items[i].$1, color: sel ? C.orange : C.muted),
              const SizedBox(width: 12),
              Text(_items[i].$2,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: sel ? C.text : C.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}
