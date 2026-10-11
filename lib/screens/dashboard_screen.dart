import 'package:flutter/material.dart';

import '../config.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/booking_detail.dart';
import '../widgets/common.dart';
import '../widgets/slot_chip.dart';

class DashboardScreen extends StatefulWidget {
  final BookCallback onBook;
  const DashboardScreen({super.key, required this.onBook});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _date = dateOnly(DateTime.now());
  List<Booking> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    bookingsVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    bookingsVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await BookingService.range(_date, _date);
      if (mounted) setState(() => _items = r);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setDate(DateTime d) {
    _date = d;
    _load();
  }

  List<Booking> _of(String court) => _items.where((b) => b.court == court).toList();

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final totalHours = _items.fold<int>(0, (s, b) => s + b.hours);
    final capacity = AppConfig.totalSlots * AppConfig.courts.length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(desktop ? 36 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Start Booking!',
                style: TextStyle(color: C.orange, fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('See which court is free and record a new booking for UiTM Kuala Terengganu.',
                style: TextStyle(color: C.muted, fontSize: 15)),
            const SizedBox(height: 20),
            DateBar(date: _date, onChanged: _setDate),
            const SizedBox(height: 20),
            if (_error != null) ...[
              ErrorBanner(message: _error!, onRetry: _load),
              const SizedBox(height: 16),
            ],
            Row(children: [
              Expanded(child: _Stat(Icons.event_available_rounded, '${_items.length}', 'Bookings', C.orange)),
              const SizedBox(width: 12),
              Expanded(child: _Stat(Icons.timer_rounded, '${totalHours}h', 'Hours booked', C.cyan)),
              const SizedBox(width: 12),
              Expanded(
                  child: _Stat(Icons.check_circle_outline_rounded, '${capacity - totalHours}h',
                      'Hours free', C.success)),
            ]),
            const SizedBox(height: 28),
            const SectionTitle('Courts', eyebrow: 'Availability'),
            const SizedBox(height: 14),
            if (_loading && _items.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: C.orange)))
            else
              LayoutBuilder(builder: (context, c) {
                final cards = [
                  for (final court in AppConfig.courts)
                    _CourtCard(
                      court: court,
                      date: _date,
                      bookings: _of(court),
                      onBook: widget.onBook,
                    ),
                ];
                if (c.maxWidth >= 820) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 18),
                    Expanded(child: cards[1]),
                  ]);
                }
                return Column(children: [cards[0], const SizedBox(height: 16), cards[1]]);
              }),
            const SizedBox(height: 28),
            SectionTitle('Bookings on ${longDate(_date)}', eyebrow: 'Schedule'),
            const SizedBox(height: 14),
            if (_items.isEmpty && !_loading)
              const NeonCard(
                  child: Row(children: [
                Icon(Icons.event_busy_rounded, color: C.muted),
                SizedBox(width: 12),
                Expanded(child: Text('No bookings yet for this day. Both courts are free.',
                    style: TextStyle(color: C.muted))),
              ]))
            else
              for (final b in _items) _BookingTile(b),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _Stat(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 12, color: C.muted)),
      ]),
    );
  }
}

class _CourtCard extends StatelessWidget {
  final String court;
  final DateTime date;
  final List<Booking> bookings;
  final BookCallback onBook;
  const _CourtCard(
      {required this.court, required this.date, required this.bookings, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final color = courtColor(court);
    final booked = BookingService.bookedHours(bookings);
    final free = AppConfig.totalSlots - booked.length;
    return NeonCard(
      glow: color,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.o(0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(courtIcon(court), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(court, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const Row(children: [
                Icon(Icons.location_on_outlined, size: 14, color: C.muted),
                SizedBox(width: 4),
                Text('UiTM Kuala Terengganu', style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (free == 0 ? C.danger : C.success).o(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (free == 0 ? C.danger : C.success).o(0.6)),
            ),
            child: Text(free == 0 ? 'Fully booked' : '$free h free',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: free == 0 ? C.danger : C.success)),
          ),
        ]),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var h = AppConfig.openHour; h < AppConfig.closeHour; h++)
            SlotChip(
              hour: h,
              accent: color,
              state: booked.contains(h) ? SlotState.booked : SlotState.free,
              onTap: () => onBook(court, date, h),
            ),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 16, runSpacing: 6, children: [
          LegendDot(label: 'Free – tap to book', color: color, filled: false),
          const LegendDot(label: 'Booked', color: C.muted, icon: Icons.lock_rounded),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: GhostButton(
              label: 'Details',
              color: color,
              onPressed: () => _showDetails(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
                label: 'Book Now', icon: Icons.arrow_forward_rounded, color: color,
                onPressed: () => onBook(court, date, null)),
          ),
        ]),
      ]),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: NeonCard(
            glow: courtColor(court),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: SectionTitle(court, eyebrow: longDate(date))),
                IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 12),
              if (bookings.isEmpty)
                const Text('No bookings. The court is free all day.', style: TextStyle(color: C.muted))
              else
                for (final b in bookings)
                  _BookingTile(b, onBeforeOpen: () => Navigator.pop(ctx)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking b;
  final VoidCallback? onBeforeOpen;
  const _BookingTile(this.b, {this.onBeforeOpen});

  @override
  Widget build(BuildContext context) {
    final color = courtColor(b.court);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          onBeforeOpen?.call();
          showBookingDetail(context, b);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: C.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.border),
          ),
          child: Row(children: [
            Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${b.sport} · ${b.timeRange}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${b.name} · ${b.phone}', style: const TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(courtIcon(b.court), size: 16, color: color),
              const SizedBox(width: 4),
              Text(b.court.replaceFirst('Court ', ''), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right_rounded, color: C.muted),
            ]),
          ]),
        ),
      ),
    );
  }
}
