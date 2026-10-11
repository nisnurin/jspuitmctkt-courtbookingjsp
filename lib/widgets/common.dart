import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils.dart';

/// Subtle futuristic grid + orange/cyan glow behind every screen.
class GridBackground extends StatelessWidget {
  final Widget child;
  const GridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: CustomPaint(painter: _GridPainter())),
      child,
    ]);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow1 = Paint()
      ..shader = RadialGradient(colors: [C.orange.o(0.16), Colors.transparent])
          .createShader(Rect.fromCircle(center: const Offset(0, 0), radius: 420));
    canvas.drawCircle(const Offset(0, 0), 420, glow1);
    final c2 = Offset(size.width, size.height);
    final glow2 = Paint()
      ..shader = RadialGradient(colors: [C.cyan.o(0.10), Colors.transparent])
          .createShader(Rect.fromCircle(center: c2, radius: 380));
    canvas.drawCircle(c2, 380, glow2);

    final line = Paint()
      ..color = Colors.white.o(0.025)
      ..strokeWidth = 1;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Rounded dark card with optional neon glow.
class NeonCard extends StatelessWidget {
  final Widget child;
  final Color? glow;
  final EdgeInsets padding;
  const NeonCard(
      {super.key,
      required this.child,
      this.glow,
      this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: C.surface.o(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glow?.o(0.55) ?? C.border),
        boxShadow: glow == null
            ? null
            : [BoxShadow(color: glow!.o(0.18), blurRadius: 28, spreadRadius: -4)],
      ),
      child: child,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  const PrimaryButton(
      {super.key,
      required this.label,
      this.icon,
      this.onPressed,
      this.loading = false,
      this.color = C.orange});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: C.onAccent,
          disabledBackgroundColor: color.o(0.35),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: C.onAccent))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label),
                if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
              ]),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  const GhostButton(
      {super.key,
      required this.label,
      this.icon,
      this.onPressed,
      this.color = C.orange});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.o(0.8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label),
        ]),
      ),
    );
  }
}

/// Pill-style segmented control (large touch targets).
class Seg<T> extends StatelessWidget {
  final List<T> values;
  final T value;
  final String Function(T) label;
  final IconData Function(T)? icon;
  final Color Function(T)? color;
  final ValueChanged<T> onChanged;
  const Seg(
      {super.key,
      required this.values,
      required this.value,
      required this.label,
      required this.onChanged,
      this.icon,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: C.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final v in values)
          Semantics(
            button: true,
            selected: v == value,
            label: label(v),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: v == value ? (color?.call(v) ?? C.orange) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[
                    Icon(icon!(v), size: 18, color: v == value ? C.onAccent : C.muted),
                    const SizedBox(width: 8),
                  ],
                  Text(label(v),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: v == value ? C.onAccent : C.muted)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Previous / date picker / next row.
class DateBar extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const DateBar({super.key, required this.date, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: C.orange, onPrimary: C.onAccent, surface: C.surface2),
        ),
        child: child!,
      ),
    );
    if (d != null) onChanged(dateOnly(d));
  }

  @override
  Widget build(BuildContext context) {
    final isToday = sameDay(date, DateTime.now());
    return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      IconButton.outlined(
        tooltip: 'Previous day',
        onPressed: () => onChanged(date.subtract(const Duration(days: 1))),
        icon: const Icon(Icons.chevron_left_rounded),
        style: IconButton.styleFrom(
            minimumSize: const Size(48, 48), side: const BorderSide(color: C.border)),
      ),
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pick(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: C.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_month_rounded, size: 20, color: C.orange),
            const SizedBox(width: 10),
            Text(longDate(date), style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      IconButton.outlined(
        tooltip: 'Next day',
        onPressed: () => onChanged(date.add(const Duration(days: 1))),
        icon: const Icon(Icons.chevron_right_rounded),
        style: IconButton.styleFrom(
            minimumSize: const Size(48, 48), side: const BorderSide(color: C.border)),
      ),
      if (!isToday)
        TextButton(
          onPressed: () => onChanged(dateOnly(DateTime.now())),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: const Text('Today'),
        ),
    ]);
  }
}

class LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;
  const LegendDot(
      {super.key, required this.label, required this.color, this.filled = true, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: filled ? color.o(0.35) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color, width: 1.5),
        ),
        child: icon == null ? null : Icon(icon, size: 11, color: color),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: C.muted)),
    ]);
  }
}

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.danger.o(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.danger.o(0.6)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: C.danger),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final String? eyebrow;
  const SectionTitle(this.text, {super.key, this.eyebrow});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (eyebrow != null)
        Text(eyebrow!.toUpperCase(),
            style: const TextStyle(
                color: C.orange, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
      Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
    ]);
  }
}
