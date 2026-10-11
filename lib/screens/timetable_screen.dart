import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/export_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/booking_detail.dart';
import '../widgets/common.dart';

enum TtMode { week, month }

const double _timeW = 78, _dayW = 128, _rowH = 54, _headH = 66;

class TimetableScreen extends StatefulWidget {
  final BookCallback onBook;
  const TimetableScreen({super.key, required this.onBook});
  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _boundary = GlobalKey();
  TtMode _mode = TtMode.week;
  String _court = AppConfig.courts.first;
  DateTime _anchor = dateOnly(DateTime.now());
  List<Booking> _items = [];
  bool _loading = true, _exporting = false;
  String? _error;

  DateTime get _from => _mode == TtMode.week
      ? weekStartOf(_anchor)
      : DateTime(_anchor.year, _anchor.month, 1);
  DateTime get _to => _mode == TtMode.week
      ? weekStartOf(_anchor).add(const Duration(days: 6))
      : DateTime(_anchor.year, _anchor.month + 1, 0);

  String get _title => _mode == TtMode.week
      ? '${DateFormat('d MMM').format(_from)} – ${DateFormat('d MMM yyyy').format(_to)}'
      : DateFormat('MMMM yyyy').format(_anchor);

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
      final r = await BookingService.range(_from, _to, court: _court);
      if (mounted) setState(() => _items = r);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _shift(int dir) {
    setState(() {
      _anchor = _mode == TtMode.week
          ? _anchor.add(Duration(days: 7 * dir))
          : DateTime(_anchor.year, _anchor.month + dir, 1);
    });
    _load();
  }

  String get _fileName {
    final c = _court.replaceAll(' ', '-');
    return _mode == TtMode.week
        ? 'timetable-$c-week-${dKey(_from)}'
        : 'timetable-$c-${DateFormat('yyyy-MM').format(_anchor)}';
  }

  Future<void> _export(bool pdf) async {
    setState(() => _exporting = true);
    try {
      final png = await ExportService.capture(_boundary);
      if (pdf) {
        await ExportService.savePdf(png, _fileName);
      } else {
        await ExportService.savePng(png, _fileName);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pdf ? 'PDF' : 'PNG'} saved: $_fileName')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not export the timetable. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openDay(DateTime day) {
    final list = _items.where((b) => sameDay(b.date, day)).toList();
    final color = courtColor(_court);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: NeonCard(
            glow: color,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: SectionTitle(longDate(day), eyebrow: _court)),
                IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const Text('No bookings. The court is free all day.', style: TextStyle(color: C.muted))
              else
                for (final b in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    minVerticalPadding: 10,
                    title: Text('${b.sport} · ${b.timeRange}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${b.name} · ${b.phone}', style: const TextStyle(color: C.muted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(ctx);
                      showBookingDetail(context, b);
                    },
                  ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Book this day',
                  icon: Icons.arrow_forward_rounded,
                  color: color,
                  onPressed: () {
                    Navigator.pop(ctx);
                    widget.onBook(_court, day, null);
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final color = courtColor(_court);
    final controls = Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Seg<String>(
        values: AppConfig.courts,
        value: _court,
        label: (c) => c,
        icon: courtIcon,
        color: courtColor,
        onChanged: (c) {
          setState(() => _court = c);
          _load();
        },
      ),
      Seg<TtMode>(
        values: TtMode.values,
        value: _mode,
        label: (m) => m == TtMode.week ? 'Week' : 'Month',
        icon: (m) => m == TtMode.week ? Icons.view_week_rounded : Icons.calendar_view_month_rounded,
        onChanged: (m) {
          setState(() => _mode = m);
          _load();
        },
      ),
    ]);

    final nav = Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      IconButton.outlined(
        tooltip: _mode == TtMode.week ? 'Previous week' : 'Previous month',
        onPressed: () => _shift(-1),
        icon: const Icon(Icons.chevron_left_rounded),
        style: IconButton.styleFrom(minimumSize: const Size(48, 48), side: const BorderSide(color: C.border)),
      ),
      Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 190),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: C.surface2, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.border)),
        child: Text(_title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      IconButton.outlined(
        tooltip: _mode == TtMode.week ? 'Next week' : 'Next month',
        onPressed: () => _shift(1),
        icon: const Icon(Icons.chevron_right_rounded),
        style: IconButton.styleFrom(minimumSize: const Size(48, 48), side: const BorderSide(color: C.border)),
      ),
      TextButton(
        onPressed: () {
          setState(() => _anchor = dateOnly(DateTime.now()));
          _load();
        },
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        child: const Text('Today'),
      ),
    ]);

    final export = Wrap(spacing: 10, runSpacing: 10, children: [
      GhostButton(
          label: 'PNG', icon: Icons.image_outlined, color: color, onPressed: _exporting ? null : () => _export(false)),
      GhostButton(
          label: 'PDF', icon: Icons.picture_as_pdf_outlined, color: color, onPressed: _exporting ? null : () => _export(true)),
    ]);

    return SingleChildScrollView(
      padding: EdgeInsets.all(desktop ? 36 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Timetable',
                style: TextStyle(color: C.orange, fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('See at a glance when each court is booked or free. Tap an empty slot to book it.',
                style: TextStyle(color: C.muted)),
            const SizedBox(height: 20),
            controls,
            const SizedBox(height: 14),
            Wrap(spacing: 20, runSpacing: 12, alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, children: [
              nav,
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (_exporting)
                  const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: C.orange))),
                const Padding(padding: EdgeInsets.only(right: 10), child: Text('Download', style: TextStyle(color: C.muted))),
                export,
              ]),
            ]),
            const SizedBox(height: 18),
            if (_error != null) ...[ErrorBanner(message: _error!, onRetry: _load), const SizedBox(height: 14)],
            if (_loading)
              const LinearProgressIndicator(color: C.orange, backgroundColor: C.surface2, minHeight: 3),
            const SizedBox(height: 10),
            NeonCard(
              padding: const EdgeInsets.all(8),
              child: _mode == TtMode.week
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _exportFrame(
                        child: _WeekGrid(
                          start: _from,
                          court: _court,
                          bookings: _items,
                          onBooking: (b) => showBookingDetail(context, b),
                          onFree: (d, h) => widget.onBook(_court, d, h),
                        ),
                      ),
                    )
                  : _exportFrame(
                      child: _MonthGrid(
                        month: _anchor,
                        court: _court,
                        bookings: _items,
                        onDay: _openDay,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  /// Everything inside this boundary ends up in the PNG / PDF.
  Widget _exportFrame({required Widget child}) {
    final color = courtColor(_court);
    return RepaintBoundary(
      key: _boundary,
      child: Container(
        color: C.bg,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(courtIcon(_court), color: color),
            const SizedBox(width: 10),
            Text('$_court · ${_mode == TtMode.week ? 'Weekly' : 'Monthly'} timetable',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 2),
          Text('$_title  |  JSP UiTM Kuala Terengganu',
              style: const TextStyle(color: C.muted, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(spacing: 16, runSpacing: 6, children: [
            LegendDot(label: 'Available', color: color, filled: false),
            LegendDot(label: 'Booked', color: color, icon: Icons.lock_rounded),
            if (_mode == TtMode.month) const LegendDot(label: 'Fully booked', color: C.danger, icon: Icons.block_rounded),
          ]),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 10),
          Text('Generated ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())}',
              style: const TextStyle(color: C.muted, fontSize: 10)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- week grid

class _WeekGrid extends StatelessWidget {
  final DateTime start;
  final String court;
  final List<Booking> bookings;
  final void Function(Booking) onBooking;
  final void Function(DateTime day, int hour) onFree;
  const _WeekGrid(
      {required this.start,
      required this.court,
      required this.bookings,
      required this.onBooking,
      required this.onFree});

  @override
  Widget build(BuildContext context) {
    final color = courtColor(court);
    final hours = [for (var h = AppConfig.openHour; h < AppConfig.closeHour; h++) h];
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // time labels
      SizedBox(
        width: _timeW,
        child: Column(children: [
          const SizedBox(height: _headH),
          for (final h in hours)
            SizedBox(
              height: _rowH,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(hourLabel(h), style: const TextStyle(fontSize: 11, color: C.muted)),
                ),
              ),
            ),
        ]),
      ),
      for (final day in days)
        SizedBox(
          width: _dayW,
          child: Column(children: [
            _dayHeader(day),
            SizedBox(
              height: _rowH * hours.length,
              child: Stack(children: [
                Column(children: [
                  for (final h in hours)
                    Semantics(
                      button: true,
                      label: 'Available ${longDate(day)} ${hourLabel(h)}. Tap to book.',
                      child: InkWell(
                        onTap: () => onFree(day, h),
                        child: Container(
                          height: _rowH,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: C.border.o(0.7)),
                              left: BorderSide(color: C.border.o(0.7)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
                for (final b in bookings.where((b) => sameDay(b.date, day)))
                  Positioned(
                    top: (b.startHour - AppConfig.openHour) * _rowH + 3,
                    left: 4,
                    right: 4,
                    height: b.hours * _rowH - 6,
                    child: _BlockView(b: b, color: color, onTap: () => onBooking(b)),
                  ),
              ]),
            ),
          ]),
        ),
    ]);
  }

  Widget _dayHeader(DateTime day) {
    final today = sameDay(day, DateTime.now());
    return Container(
      height: _headH,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: C.border.o(0.7))),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(DateFormat('EEE').format(day).toUpperCase(),
            style: TextStyle(
                fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: today ? C.orange : C.muted)),
        const SizedBox(height: 4),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: today ? C.orange : Colors.transparent,
          ),
          child: Text('${day.day}',
              style: TextStyle(fontWeight: FontWeight.w800, color: today ? C.onAccent : C.text)),
        ),
      ]),
    );
  }
}

class _BlockView extends StatelessWidget {
  final Booking b;
  final Color color;
  final VoidCallback onTap;
  const _BlockView({required this.b, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Booked: ${b.sport}, ${b.timeRange}, by ${b.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: color.o(0.2),
              border: Border.all(color: color.o(0.6)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                  child: ClipRect(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Icon(Icons.lock_rounded, size: 11, color: color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(b.sport,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ]),
                      Text(b.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: C.muted)),
                      if (b.hours > 1)
                        Text(b.timeRange,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: C.muted)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- month grid

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final String court;
  final List<Booking> bookings;
  final void Function(DateTime) onDay;
  const _MonthGrid(
      {required this.month, required this.court, required this.bookings, required this.onDay});

  @override
  Widget build(BuildContext context) {
    final color = courtColor(court);
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday - 1;
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    final rows = ((lead + count) / 7).ceil();

    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth.isFinite ? c.maxWidth : 7 * 120.0;
      final compact = w < 560;
      return SizedBox(
        width: w,
        child: Column(children: [
          Row(children: [
            for (final d in const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                      child: Text(compact ? d.substring(0, 1) : d.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: C.muted))),
                ),
              ),
          ]),
          for (var r = 0; r < rows; r++)
            Row(children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _cell(r * 7 + col - lead + 1, count, color, compact)),
            ]),
        ]),
      );
    });
  }

  Widget _cell(int dayNum, int count, Color color, bool compact) {
    final h = compact ? 66.0 : 92.0;
    if (dayNum < 1 || dayNum > count) return SizedBox(height: h);
    final day = DateTime(month.year, month.month, dayNum);
    final booked = BookingService.bookedHours(bookings.where((b) => sameDay(b.date, day))).length;
    final total = AppConfig.totalSlots;
    final full = booked >= total;
    final today = sameDay(day, DateTime.now());
    final accent = full ? C.danger : color;
    final label = full ? 'Full' : (booked == 0 ? 'Free' : '${booked}h');

    return Semantics(
      button: true,
      label: '${longDate(day)}, ${full ? 'fully booked' : (booked == 0 ? 'free all day' : '$booked of $total hours booked')}',
      child: InkWell(
        onTap: () => onDay(day),
        child: Container(
          height: h,
          margin: const EdgeInsets.all(2),
          padding: EdgeInsets.all(compact ? 5 : 9),
          decoration: BoxDecoration(
            color: booked == 0 ? C.surface : accent.o(0.08 + 0.22 * (booked / total)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: today ? C.orange : (booked == 0 ? C.border : accent.o(0.6)), width: today ? 2 : 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$dayNum',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: compact ? 13 : 15, color: today ? C.orange : C.text)),
            const Spacer(),
            Row(children: [
              if (full && !compact) Padding(padding: const EdgeInsets.only(right: 3), child: Icon(Icons.block_rounded, size: 12, color: accent)),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: compact ? 10 : 12,
                        fontWeight: FontWeight.w700,
                        color: booked == 0 ? C.muted : accent)),
              ),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: booked / total,
                minHeight: 4,
                backgroundColor: C.border,
                color: accent,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
