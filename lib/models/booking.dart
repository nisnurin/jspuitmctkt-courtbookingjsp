import '../utils.dart';

class Booking {
  final String id;
  final String court;
  final DateTime date;
  final int startHour; // inclusive, 0-23
  final int endHour; // exclusive, 1-24 (24 = midnight)
  final String sport;
  final String name;
  final String phone;
  final String? note;

  const Booking({
    required this.id,
    required this.court,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.sport,
    required this.name,
    required this.phone,
    this.note,
  });

  int get hours => endHour - startHour;
  String get timeRange => rangeLabel(startHour, endHour);
  bool covers(int hour) => hour >= startHour && hour < endHour;

  factory Booking.fromMap(Map<String, dynamic> m) {
    final d = DateTime.parse(m['booking_date'] as String);
    return Booking(
      id: m['id'] as String,
      court: m['court'] as String,
      date: DateTime(d.year, d.month, d.day),
      startHour: (m['start_hour'] as num).toInt(),
      endHour: (m['end_hour'] as num).toInt(),
      sport: m['sport'] as String,
      name: m['name'] as String,
      phone: m['phone'] as String,
      note: m['note'] as String?,
    );
  }
}
