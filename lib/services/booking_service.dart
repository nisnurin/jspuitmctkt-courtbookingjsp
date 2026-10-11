import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../utils.dart';

/// Bumped after every create/delete so open screens reload themselves.
final ValueNotifier<int> bookingsVersion = ValueNotifier<int>(0);

class BookingService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<Booking>> range(DateTime from, DateTime to,
      {String? court}) async {
    var q = _db
        .from('bookings')
        .select()
        .gte('booking_date', dKey(from))
        .lte('booking_date', dKey(to));
    if (court != null) {
      q = q.eq('court', court);
    }
    final rows = await q.order('booking_date').order('start_hour');
    return rows.map<Booking>((r) => Booking.fromMap(r)).toList();
  }

  static Future<void> create({
    required String court,
    required DateTime date,
    required int startHour,
    required int endHour,
    required String sport,
    required String name,
    required String phone,
    String? note,
  }) async {
    try {
      await _db.from('bookings').insert({
        'court': court,
        'booking_date': dKey(date),
        'start_hour': startHour,
        'end_hour': endHour,
        'sport': sport,
        'name': name,
        'phone': phone,
        'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      });
      bookingsVersion.value++;
    } on PostgrestException catch (e) {
      // 23P01 = exclusion violation -> overlapping booking
      if (e.code == '23P01') throw SlotTakenException();
      rethrow;
    }
  }

  static Future<void> delete(String id) async {
    await _db.from('bookings').delete().eq('id', id);
    bookingsVersion.value++;
  }

  static Set<int> bookedHours(Iterable<Booking> list) {
    final s = <int>{};
    for (final b in list) {
      for (var h = b.startHour; h < b.endHour; h++) {
        s.add(h);
      }
    }
    return s;
  }
}
