import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String hourLabel(int h) => DateFormat('h:mm a').format(DateTime(2000, 1, 1, h % 24));
String rangeLabel(int s, int e) => '${hourLabel(s)} – ${hourLabel(e)}';
String dKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime weekStartOf(DateTime d) =>
    dateOnly(d).subtract(Duration(days: d.weekday - 1));
String longDate(DateTime d) => DateFormat('EEE, d MMM yyyy').format(d);
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isDesktop(BuildContext c) => MediaQuery.of(c).size.width >= 900;

String friendlyError(Object e) {
  if (e is SlotTakenException) return e.message;
  if (e is AuthException) return e.message;
  if (e is PostgrestException) return e.message;
  return 'Something went wrong. Please check your connection and try again.';
}

class SlotTakenException implements Exception {
  final String message =
      'Sorry, that time was just booked by someone else. Please pick another slot.';
}

/// Jump to the booking form with a court / date / start hour pre-filled.
typedef BookCallback = void Function(String court, DateTime date, int? hour);
