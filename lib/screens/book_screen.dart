import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/slot_chip.dart';

class BookScreen extends StatefulWidget {
  final String? initialCourt;
  final DateTime? initialDate;
  final int? initialHour;
  const BookScreen({super.key, this.initialCourt, this.initialDate, this.initialHour});
  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  late String _court = widget.initialCourt ?? AppConfig.courts.first;
  late DateTime _date = widget.initialDate ?? dateOnly(DateTime.now());
  String _sport = AppConfig.sports.first;

  List<Booking> _items = [];
  bool _loading = true, _saving = false;
  String? _error;

  // Selected range of hour slots (inclusive). null = nothing chosen.
  int? _from, _to;
  int? _anchor; // first tap waiting for the second tap

  Set<int> get _booked => BookingService.bookedHours(_items);

  @override
  void initState() {
    super.initState();
    final h = widget.initialHour;
    if (h != null) {
      _from = _to = h;
    }
    bookingsVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    bookingsVersion.removeListener(_load);
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await BookingService.range(_date, _date, court: _court);
      if (!mounted) return;
      setState(() {
        _items = r;
        // drop a selection that is no longer free
        final b = BookingService.bookedHours(r);
        if (_from != null && [for (var h = _from!; h <= _to!; h++) h].any(b.contains)) {
          _from = _to = _anchor = null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() => _from = _to = _anchor = null;

  void _tapSlot(int h) {
    setState(() {
      if (_anchor == null) {
        _anchor = h;
        _from = _to = h;
        return;
      }
      final lo = h < _anchor! ? h : _anchor!;
      final hi = h < _anchor! ? _anchor! : h;
      final clash = [for (var x = lo; x <= hi; x++) x].any(_booked.contains);
      if (clash) {
        // range crosses a booked hour -> start again from this slot
        _anchor = h;
        _from = _to = h;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('That range includes a booked hour. Starting again from this slot.')));
      } else {
        _from = lo;
        _to = hi;
        _anchor = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_from == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please choose a start time (and end time) first.')));
      return;
    }
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await BookingService.create(
        court: _court,
        date: _date,
        startHour: _from!,
        endHour: _to! + 1,
        sport: _sport,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        note: _note.text,
      );
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => _Success(
          court: _court,
          date: _date,
          range: rangeLabel(_from!, _to! + 1),
          sport: _sport,
          name: _name.text.trim(),
        ),
      );
      if (!mounted) return;
      _name.clear();
      _phone.clear();
      _note.clear();
      setState(_reset);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
        _load();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---- UI sections ---------------------------------------------------------

  Widget _courtPicker() => Row(children: [
        for (final c in AppConfig.courts) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: c == _court,
              label: c,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _court = c;
                    _reset();
                  });
                  _load();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  constraints: const BoxConstraints(minHeight: 72),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c == _court ? courtColor(c).o(0.14) : C.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: c == _court ? courtColor(c) : C.border, width: c == _court ? 2 : 1),
                    boxShadow: c == _court
                        ? [BoxShadow(color: courtColor(c).o(0.25), blurRadius: 18, spreadRadius: -4)]
                        : null,
                  ),
                  child: Row(children: [
                    Icon(courtIcon(c), color: courtColor(c)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(c, style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (c == _court) Icon(Icons.check_circle_rounded, color: courtColor(c), size: 20),
                  ]),
                ),
              ),
            ),
          ),
          if (c != AppConfig.courts.last) const SizedBox(width: 12),
        ]
      ]);

  Widget _slots() {
    final color = courtColor(_court);
    final booked = _booked;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tap a start time, then tap an end time. Tap the same slot twice for one hour.',
          style: TextStyle(color: C.muted, fontSize: 13)),
      const SizedBox(height: 12),
      if (_loading)
        const Padding(
            padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: C.orange)))
      else
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (var h = AppConfig.openHour; h < AppConfig.closeHour; h++)
            SlotChip(
              hour: h,
              accent: color,
              state: booked.contains(h)
                  ? SlotState.booked
                  : (_from != null && h >= _from! && h <= _to! ? SlotState.selected : SlotState.free),
              onTap: () => _tapSlot(h),
            ),
        ]),
      const SizedBox(height: 14),
      Wrap(spacing: 16, runSpacing: 6, children: [
        LegendDot(label: 'Free', color: color, filled: false),
        LegendDot(label: 'Selected', color: color, icon: Icons.check_rounded),
        const LegendDot(label: 'Booked', color: C.muted, icon: Icons.lock_rounded),
      ]),
    ]);
  }

  Widget _formCard() {
    final color = courtColor(_court);
    return NeonCard(
      glow: color,
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Booker details', eyebrow: 'Step 3'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Enter the student\'s name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
            decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: 'e.g. 012-3456789',
                prefixIcon: Icon(Icons.phone_outlined)),
            validator: (v) {
              final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
              return (d.length < 9 || d.length > 13) ? 'Enter a valid phone number' : null;
            },
          ),
          const SizedBox(height: 18),
          const Text('Sport', style: TextStyle(color: C.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in AppConfig.sports)
              ChoiceChip(
                label: Text(s),
                selected: s == _sport,
                onSelected: (_) => setState(() => _sport = s),
                showCheckmark: true,
                checkmarkColor: C.onAccent,
                selectedColor: color,
                backgroundColor: C.surface2,
                side: BorderSide(color: s == _sport ? color : C.border),
                labelStyle: TextStyle(
                    color: s == _sport ? C.onAccent : C.text, fontWeight: FontWeight.w600, fontSize: 13),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                visualDensity: VisualDensity.comfortable,
              ),
          ]),
          const SizedBox(height: 18),
          TextFormField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Handball tour training',
                prefixIcon: Icon(Icons.notes_rounded)),
          ),
          const SizedBox(height: 20),
          _summary(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Confirm booking',
              icon: Icons.check_rounded,
              color: color,
              loading: _saving,
              onPressed: _submit,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _summary() {
    final color = courtColor(_court);
    final has = _from != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: has ? color.o(0.6) : C.border),
      ),
      child: Row(children: [
        Icon(has ? Icons.event_available_rounded : Icons.info_outline_rounded,
            color: has ? color : C.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            has
                ? '$_court · ${longDate(_date)}\n${rangeLabel(_from!, _to! + 1)} (${_to! - _from! + 1} hr)'
                : 'No time chosen yet. Pick your hours above.',
            style: TextStyle(
                fontSize: 13, height: 1.45, color: has ? C.text : C.muted, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final left = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Choose court & date', eyebrow: 'Step 1'),
      const SizedBox(height: 14),
      _courtPicker(),
      const SizedBox(height: 16),
      DateBar(
        date: _date,
        onChanged: (d) {
          setState(() {
            _date = d;
            _reset();
          });
          _load();
        },
      ),
      const SizedBox(height: 28),
      const SectionTitle('Pick your hours', eyebrow: 'Step 2'),
      const SizedBox(height: 14),
      if (_error != null) ...[ErrorBanner(message: _error!, onRetry: _load), const SizedBox(height: 14)],
      _slots(),
    ]);

    return SingleChildScrollView(
      padding: EdgeInsets.all(desktop ? 36 : 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('New booking',
                style: TextStyle(color: C.orange, fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Record a court booking. Bookings are per hour (8:00 AM – 12:00 AM).',
                style: TextStyle(color: C.muted)),
            const SizedBox(height: 24),
            if (desktop)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: 28),
                Expanded(flex: 4, child: _formCard()),
              ])
            else ...[left, const SizedBox(height: 28), _formCard()],
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  final String court, range, sport, name;
  final DateTime date;
  const _Success(
      {required this.court, required this.date, required this.range, required this.sport, required this.name});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: NeonCard(
          glow: C.success,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: C.success, size: 56),
            const SizedBox(height: 12),
            const Text('Booking confirmed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text('$sport · $court\n${longDate(date)}\n$range\nBooked by $name',
                textAlign: TextAlign.center, style: const TextStyle(color: C.muted, height: 1.6)),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: PrimaryButton(label: 'Done', color: C.success, onPressed: () => Navigator.pop(context))),
          ]),
        ),
      ),
    );
  }
}
