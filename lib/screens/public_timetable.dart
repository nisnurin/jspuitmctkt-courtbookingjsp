import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../services/booking_service.dart';
import '../theme.dart';
import '../utils.dart';

class PublicTimetable extends StatefulWidget {
  final VoidCallback onLogin, onToggleTheme;
  final bool isDark;
  const PublicTimetable({super.key, required this.onLogin, required this.onToggleTheme, required this.isDark});
  @override
  State<PublicTimetable> createState() => _PublicTimetableState();
}

class _PublicTimetableState extends State<PublicTimetable> {
  DateTime _anchor = dateOnly(DateTime.now());
  String _court = AppConfig.courtKolej;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  DateTime get _start => weekStartOf(_anchor);

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await BookingService.publicRange(_start, _start.add(const Duration(days: 6)));
      if (mounted) setState(() => _rows = data);
    } catch (_) { if (mounted) setState(() => _error = 'Availability could not be loaded. Please try again.'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final color = courtColor(_court);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const Icon(Icons.sports_basketball_rounded, color: C.orange), const SizedBox(width: 10), const Flexible(child: Text('JSP Courts', style: TextStyle(fontWeight: FontWeight.w800)))]),
        actions: [
          IconButton(tooltip: widget.isDark ? 'Switch to light mode' : 'Switch to dark mode', onPressed: widget.onToggleTheme, icon: Icon(widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded)),
          if (MediaQuery.sizeOf(context).width > 520) TextButton.icon(onPressed: widget.onLogin, icon: const Icon(Icons.login_rounded), label: const Text('Log in')) else IconButton(tooltip: 'Log in', onPressed: widget.onLogin, icon: const Icon(Icons.login_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: ListView(padding: const EdgeInsets.all(18), children: [
        Text('Court timetable', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Check weekly availability for Court Kolej and Court Kampus. Sign in to make a booking.', style: TextStyle(color: cs.onSurface.withValues(alpha: .68))),
        const SizedBox(height: 18),
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 12, runSpacing: 12, children: [
          SegmentedButton<String>(segments: [for (final c in AppConfig.courts) ButtonSegment(value: c, label: Text(c), icon: Icon(courtIcon(c)))], selected: {_court}, onSelectionChanged: (v) => setState(() => _court = v.first)),
          Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () { setState(() => _anchor = _anchor.subtract(const Duration(days: 7))); _load(); }, icon: const Icon(Icons.chevron_left)), Text('${DateFormat('d MMM').format(_start)} – ${DateFormat('d MMM yyyy').format(_start.add(const Duration(days: 6)))}', style: const TextStyle(fontWeight: FontWeight.w700)), IconButton(onPressed: () { setState(() => _anchor = _anchor.add(const Duration(days: 7))); _load(); }, icon: const Icon(Icons.chevron_right)), TextButton(onPressed: () { setState(() => _anchor = dateOnly(DateTime.now())); _load(); }, child: const Text('Today'))]),
        ]),
        const SizedBox(height: 12),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[Text(_error!, style: const TextStyle(color: Colors.red)), TextButton(onPressed: _load, child: const Text('Retry'))],
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(courtIcon(_court), color: color), const SizedBox(width: 8), Text(_court, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const Spacer(), const Icon(Icons.circle, size: 10, color: Colors.green), const SizedBox(width: 5), const Text('Free'), const SizedBox(width: 12), Icon(Icons.circle, size: 10, color: color), const SizedBox(width: 5), const Text('Booked')]),
          const SizedBox(height: 14),
          for (var i=0; i<7; i++) _dayCard(_start.add(Duration(days:i)), color),
        ]))),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: widget.onLogin, icon: const Icon(Icons.login_rounded), label: const Text('Log in to book a court')),
        const SizedBox(height: 10),
        Center(child: Text('Availability only · booking details are private', style: TextStyle(color: cs.onSurface.withValues(alpha:.58), fontSize: 12))),
      ])))),
    );
  }

  Widget _dayCard(DateTime day, Color color) {
    const slots = AppConfig.closeHour - AppConfig.openHour;
    final occupied = <int>{};
    for (final r in _rows.where((r) => r['court'] == _court && sameDay(DateTime.parse(r['booking_date'].toString()), day))) {
      for (var h = (r['start_hour'] as num).toInt(); h < (r['end_hour'] as num).toInt(); h++) { occupied.add(h); }
    }
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(DateFormat('EEEE, d MMM').format(day), style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [for (var h=AppConfig.openHour; h<AppConfig.closeHour; h++) _slot(h, occupied.contains(h), color)]),
      const SizedBox(height: 6),
      Text('${occupied.length} of $slots hours booked', style: const TextStyle(fontSize: 11, color: C.muted)),
      const Divider(height: 16),
    ]));
  }

  Widget _slot(int hour, bool booked, Color color) => Container(
    width: 72, padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
    decoration: BoxDecoration(color: booked ? color.withValues(alpha: .15) : Colors.green.withValues(alpha: .12), borderRadius: BorderRadius.circular(8), border: Border.all(color: booked ? color.withValues(alpha: .5) : Colors.green.withValues(alpha: .45))),
    child: Column(children: [Text(hourLabel(hour), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)), Text(booked ? 'Booked' : 'Free', style: TextStyle(fontSize: 10, color: booked ? color : Colors.green.shade700))]),
  );
}
