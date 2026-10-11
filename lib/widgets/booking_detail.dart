import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import '../theme.dart';
import '../utils.dart';
import 'common.dart';

Future<void> showBookingDetail(BuildContext context, Booking b) {
  return showDialog(context: context, builder: (_) => _BookingDetail(b));
}

class _BookingDetail extends StatefulWidget {
  final Booking b;
  const _BookingDetail(this.b);
  @override
  State<_BookingDetail> createState() => _BookingDetailState();
}

class _BookingDetailState extends State<_BookingDetail> {
  bool _busy = false;

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel this booking?'),
        content: const Text('The time slot will become available again. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: C.danger, foregroundColor: C.onAccent),
            child: const Text('Yes, cancel booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await BookingService.delete(widget.b.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  Widget _row(IconData i, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, size: 18, color: C.muted),
          const SizedBox(width: 12),
          SizedBox(width: 70, child: Text(k, style: const TextStyle(color: C.muted, fontSize: 13))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    final color = courtColor(b.court);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: NeonCard(
          glow: color,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(courtIcon(b.court), color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(b.court, style: TextStyle(color: color, fontWeight: FontWeight.w700))),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ]),
            Text(b.sport, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            _row(Icons.event_rounded, 'Date', longDate(b.date)),
            _row(Icons.schedule_rounded, 'Time', '${b.timeRange} (${b.hours} hr)'),
            _row(Icons.person_rounded, 'Name', b.name),
            _row(Icons.phone_rounded, 'Phone', b.phone),
            if (b.note != null) _row(Icons.notes_rounded, 'Note', b.note!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GhostButton(
                label: _busy ? 'Cancelling…' : 'Cancel booking',
                icon: Icons.delete_outline_rounded,
                color: C.danger,
                onPressed: _busy ? null : _cancel,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
