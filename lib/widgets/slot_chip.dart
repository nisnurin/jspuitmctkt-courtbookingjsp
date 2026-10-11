import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils.dart';

enum SlotState { free, booked, selected }

/// One bookable hour. State is conveyed by colour + icon + text label.
class SlotChip extends StatelessWidget {
  final int hour;
  final SlotState state;
  final Color accent;
  final VoidCallback? onTap;
  const SlotChip(
      {super.key,
      required this.hour,
      required this.state,
      required this.accent,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final booked = state == SlotState.booked;
    final selected = state == SlotState.selected;
    final fg = selected ? C.onAccent : (booked ? C.muted.o(0.7) : C.text);
    final status = selected ? 'Selected' : (booked ? 'Booked' : 'Free');
    return Semantics(
      button: !booked,
      enabled: !booked,
      selected: selected,
      label: '${hourLabel(hour)}, $status',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: booked ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 98,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? accent : (booked ? C.surface2 : C.surface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? accent : (booked ? C.border : accent.o(0.55)),
                width: selected ? 2 : 1),
            boxShadow: selected
                ? [BoxShadow(color: accent.o(0.35), blurRadius: 16, spreadRadius: -2)]
                : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(hourLabel(hour),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: fg,
                    decoration: booked ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 2),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : (booked ? Icons.lock_rounded : Icons.radio_button_unchecked_rounded),
                  size: 12,
                  color: fg),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(fontSize: 11, color: fg)),
            ]),
          ]),
        ),
      ),
    );
  }
}
