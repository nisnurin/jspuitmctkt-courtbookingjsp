import 'dart:math';
import 'dart:ui' as ui;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const supaUrl = 'https://YOUR-PROJECT.supabase.co'; // <-- change
const supaKey = 'YOUR-ANON-KEY'; // <-- change
const openH = 8, closeH = 24; // bookable hours 8 AM - 12 AM
const courts = {'kolej': 'Court Kolej', 'kampus': 'Court Kampus'};
const bg = Color(0xFF0A0F22), card = Color(0xFF141B33), gold = Color(0xFFF5B301);

SupabaseClient get db => Supabase.instance.client;
String hl(int h) { h %= 24; return h == 0 ? '12 AM' : h < 12 ? '$h AM' : h == 12 ? '12 PM' : '${h - 12} PM'; }
String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
DateTime dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class Slot {
  final String gid, court, sport, name, phone;
  final DateTime date;
  final int hour;
  Slot(Map m)
      : gid = m['group_id'], court = m['court'], sport = m['sport'], name = m['booker_name'],
        phone = m['phone'], date = DateTime.parse(m['booking_date']), hour = m['hour'];
}

Future<List<Slot>> fetch(String court, DateTime a, DateTime b) async =>
    (await db.from('bookings').select().eq('court', court).gte('booking_date', ymd(a)).lte('booking_date', ymd(b)))
        .map<Slot>((e) => Slot(e)).toList();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supaUrl, anonKey: supaKey);
  runApp(MaterialApp(
    title: 'JSP Court Booking',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark)
          .copyWith(primary: gold, onPrimary: Colors.black, surface: card),
      appBarTheme: const AppBarTheme(backgroundColor: card),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    ),
    home: StreamBuilder<AuthState>(
      stream: db.auth.onAuthStateChange,
      builder: (_, __) => db.auth.currentSession == null ? const Login() : const Home(),
    ),
  ));
}

class Login extends StatefulWidget {
  const Login({super.key});
  @override State<Login> createState() => _LoginState();
}
class _LoginState extends State<Login> {
  final e = TextEditingController(), p = TextEditingController();
  String? err; bool busy = false;
  Future<void> go() async {
    setState(() { busy = true; err = null; });
    try { await db.auth.signInWithPassword(email: e.text.trim(), password: p.text); }
    on AuthException catch (x) { err = x.message; }
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext c) => Scaffold(
    body: Center(child: SingleChildScrollView(child: SizedBox(width: 380, child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Image.asset('assets/logo.png', height: 140),
        const SizedBox(height: 12),
        const Text('Court Booking · JSP UiTM Terengganu', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: e, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 10),
        TextField(controller: p, obscureText: true, onSubmitted: (_) => go(), decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : go, child: const Text('Log in'))),
        if (err != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(err!, style: const TextStyle(color: Colors.redAccent))),
      ]),
    )))),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override State<Home> createState() => _HomeState();
}
class _HomeState extends State<Home> {
  String court = 'kolej'; bool month = false; bool busy = true;
  DateTime focus = dOnly(DateTime.now());
  List<Slot> slots = [];
  final key = GlobalKey();

  DateTime get start => month ? DateTime(focus.year, focus.month, 1) : focus.subtract(Duration(days: focus.weekday - 1));
  DateTime get end => month ? DateTime(focus.year, focus.month + 1, 0) : start.add(const Duration(days: 6));
  String get title => '${courts[court]} · ${month ? DateFormat('MMMM yyyy').format(focus) : '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(end)}'}';
  Map<String, Slot> get idx => {for (final s in slots) '${ymd(s.date)}|${s.hour}': s};

  @override void initState() { super.initState(); load(); }
  void msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> load() async {
    setState(() => busy = true);
    try { slots = await fetch(court, start, end); } catch (e) { msg('$e'); }
    if (mounted) setState(() => busy = false);
  }
  void move(int n) { focus = month ? DateTime(focus.year, focus.month + n, 1) : focus.add(Duration(days: 7 * n)); load(); }

  Future<void> book({DateTime? d, int? h}) async {
    final r = await showDialog<String>(context: context, builder: (_) => BookDialog(court: court, date: d ?? dOnly(DateTime.now()), hour: h));
    if (r != null) court = r;
    load();
  }

  void detail(Slot s) {
    final hs = slots.where((x) => x.gid == s.gid).map((x) => x.hour).toList()..sort();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(s.sport),
      content: Text('${courts[s.court]}\n${DateFormat('EEE d MMM yyyy').format(s.date)}\n${hl(hs.first)} – ${hl(hs.last + 1)}\n${s.name} · ${s.phone}'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        TextButton(
          onPressed: () async { Navigator.pop(context); await db.from('bookings').delete().eq('group_id', s.gid); load(); },
          child: const Text('Delete booking', style: TextStyle(color: Colors.redAccent))),
      ],
    ));
  }

  Future<void> save({bool png = false}) async {
    final name = '${court}_${month ? DateFormat('yyyy-MM').format(focus) : ymd(start)}';
    try {
      if (png) {
        final img = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 2.5);
        final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
        await FileSaver.instance.saveFile(name: name, bytes: bytes, ext: 'png', mimeType: MimeType.png);
      } else {
        await FileSaver.instance.saveFile(name: name, bytes: await pdfDoc().save(), ext: 'pdf', mimeType: MimeType.pdf);
      }
      msg('Downloaded $name');
    } catch (e) { msg('$e'); }
  }

  pw.Document pdfDoc() {
    final doc = pw.Document();
    pw.Widget t(String s, {bool b = false, PdfColor? fill}) => pw.Container(
        padding: const pw.EdgeInsets.all(3), color: fill, alignment: pw.Alignment.center,
        child: pw.Text(s, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 7, fontWeight: b ? pw.FontWeight.bold : pw.FontWeight.normal)));
    final rows = <pw.TableRow>[];
    if (month) {
      final g = <String, List<Slot>>{};
      for (final s in slots) { g.putIfAbsent(s.gid, () => []).add(s); }
      final list = g.values.map((l) { l.sort((a, b) => a.hour - b.hour); return l; }).toList()
        ..sort((a, b) => a.first.date != b.first.date ? a.first.date.compareTo(b.first.date) : a.first.hour - b.first.hour);
      rows.add(pw.TableRow(children: [for (final h in ['Date', 'Time', 'Sport', 'Name', 'Phone']) t(h, b: true, fill: PdfColors.grey300)]));
      for (final l in list) {
        rows.add(pw.TableRow(children: [
          t(DateFormat('EEE d MMM').format(l.first.date)), t('${hl(l.first.hour)} – ${hl(l.last.hour + 1)}'),
          t(l.first.sport), t(l.first.name), t(l.first.phone)]));
      }
    } else {
      final ix = idx;
      final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
      rows.add(pw.TableRow(children: [t('Time', b: true, fill: PdfColors.grey300), for (final d in days) t(DateFormat('EEE d/M').format(d), b: true, fill: PdfColors.grey300)]));
      for (var h = openH; h < closeH; h++) {
        rows.add(pw.TableRow(children: [
          t('${hl(h)} – ${hl(h + 1)}', b: true),
          for (final d in days) ix['${ymd(d)}|$h'] == null ? t('') : t('${ix['${ymd(d)}|$h']!.sport}\n${ix['${ymd(d)}|$h']!.name}', fill: PdfColors.red100),
        ]));
      }
    }
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape, margin: const pw.EdgeInsets.all(20),
      build: (_) => [
        pw.Text('JSP UiTM Terengganu · $title', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text(month ? 'Booked slots' : 'Red = booked, blank = available', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 6),
        pw.Table(border: pw.TableBorder.all(width: .4), defaultColumnWidth: const pw.FlexColumnWidth(), children: rows),
      ],
    ));
    return doc;
  }

  Widget box(Widget ch, Color col, double w, {VoidCallback? tap}) => Padding(
    padding: const EdgeInsets.all(1.5),
    child: Material(color: col, borderRadius: BorderRadius.circular(8), child: InkWell(
      borderRadius: BorderRadius.circular(8), onTap: tap,
      child: SizedBox(width: w, height: 44, child: Center(child: ch)))),
  );

  Widget weekGrid(double w) {
    final ix = idx;
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    const small = TextStyle(fontSize: 11);
    return Column(children: [
      Row(children: [
        box(const Text(''), Colors.transparent, 64),
        for (final d in days) box(Text(DateFormat('EEE d/M').format(d), style: TextStyle(fontWeight: FontWeight.bold, color: d == dOnly(DateTime.now()) ? gold : null)), const Color(0xFF1B2547), w),
      ]),
      for (var h = openH; h < closeH; h++) Row(children: [
        box(Text(hl(h), style: small), Colors.transparent, 64),
        for (final d in days) () {
          final s = ix['${ymd(d)}|$h'];
          return s == null
              ? box(const Text('Free', style: TextStyle(fontSize: 11, color: Color(0xFF4CAF7A))), const Color(0xFF0F2A22), w, tap: () => book(d: d, h: h))
              : box(Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(s.sport, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9)),
                ]), const Color(0xFF5A2330), w, tap: () => detail(s));
        }(),
      ]),
    ]);
  }

  Widget monthGrid(double w) {
    final off = start.weekday - 1, n = end.day, rows = ((off + n) / 7).ceil();
    Widget cell(int r, int c) {
      final day = r * 7 + c - off + 1;
      if (day < 1 || day > n) return SizedBox(width: w + 3, height: 96);
      final d = DateTime(start.year, start.month, day);
      final ss = slots.where((s) => s.date == d).toList();
      final pct = ss.length / (closeH - openH);
      return Padding(padding: const EdgeInsets.all(1.5), child: Material(
        color: card, borderRadius: BorderRadius.circular(8),
        child: InkWell(borderRadius: BorderRadius.circular(8),
          onTap: () { month = false; focus = d; load(); },
          child: Container(width: w, height: 93, padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$day', style: TextStyle(fontWeight: FontWeight.bold, color: d == dOnly(DateTime.now()) ? gold : null)),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: pct, color: pct >= 1 ? Colors.redAccent : pct > .5 ? Colors.orange : const Color(0xFF4CAF7A)),
            const SizedBox(height: 4),
            Text('${ss.length}/${closeH - openH} h booked', style: const TextStyle(fontSize: 10)),
            Text(ss.map((s) => s.sport).toSet().take(2).join(', '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white60)),
          ])))));
    }
    return Column(children: [
      Row(children: [for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) SizedBox(width: w + 3, child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold))))]),
      for (var r = 0; r < rows; r++) Row(children: [for (var c = 0; c < 7; c++) cell(r, c)]),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('JSP Court Booking · UiTM Terengganu'), actions: [
      IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout), onPressed: () => db.auth.signOut())]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => book(), icon: const Icon(Icons.add), label: const Text('New booking')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SegmentedButton<String>(
          segments: [for (final e in courts.entries) ButtonSegment(value: e.key, label: Text(e.value))],
          selected: {court}, onSelectionChanged: (s) { court = s.first; load(); }),
        SegmentedButton<bool>(
          segments: const [ButtonSegment(value: false, label: Text('Week')), ButtonSegment(value: true, label: Text('Month'))],
          selected: {month}, onSelectionChanged: (s) { month = s.first; load(); }),
        IconButton(onPressed: () => move(-1), icon: const Icon(Icons.chevron_left)),
        IconButton(onPressed: () { focus = dOnly(DateTime.now()); load(); }, icon: const Icon(Icons.today)),
        IconButton(onPressed: () => move(1), icon: const Icon(Icons.chevron_right)),
        OutlinedButton.icon(onPressed: () => save(png: true), icon: const Icon(Icons.image), label: const Text('PNG')),
        OutlinedButton.icon(onPressed: save, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
      ])),
      Expanded(child: busy ? const Center(child: CircularProgressIndicator()) : LayoutBuilder(builder: (_, bc) {
        final w = max(month ? 100.0 : 104.0, (bc.maxWidth - (month ? 40 : 110)) / 7);
        return SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: RepaintBoundary(key: key,
          child: Container(color: bg, padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: gold)),
            const Text('Green = available · Red = booked', style: TextStyle(fontSize: 11, color: Colors.white60)),
            const SizedBox(height: 8),
            month ? monthGrid(w) : weekGrid(w),
          ])))));
      })),
    ]),
  );
}

class BookDialog extends StatefulWidget {
  final String court; final DateTime date; final int? hour;
  const BookDialog({super.key, required this.court, required this.date, this.hour});
  @override State<BookDialog> createState() => _BookState();
}
class _BookState extends State<BookDialog> {
  late String court = widget.court;
  late DateTime date = widget.date;
  int? a, b;
  List<Slot> day = [];
  final f = GlobalKey<FormState>();
  final sport = TextEditingController(), name = TextEditingController(), phone = TextEditingController();
  bool saving = false;

  @override void initState() { super.initState(); a = b = widget.hour; load(); }
  Future<void> load() async { final r = await fetch(court, date, date); if (mounted) setState(() => day = r); }
  Slot? taken(int h) { for (final s in day) { if (s.hour == h) return s; } return null; }
  bool off(int h) => taken(h) != null || (date == dOnly(DateTime.now()) && h < DateTime.now().hour);
  void msg(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  void tap(int h) => setState(() {
    if (a != null && !(h >= a! && h <= b!)) {
      final lo = min(h, a!), hi = max(h, b!);
      if ([for (var x = lo; x <= hi; x++) x].every((x) => !off(x))) { a = lo; b = hi; return; }
    }
    a = b = (a == h && b == h) ? null : h;
  });

  Future<void> submit() async {
    if (!f.currentState!.validate()) return;
    if (a == null) { msg('Pick at least one hour'); return; }
    setState(() => saving = true);
    final g = const Uuid().v4();
    try {
      await db.from('bookings').insert([for (var h = a!; h <= b!; h++) {
        'group_id': g, 'court': court, 'booking_date': ymd(date), 'hour': h,
        'sport': sport.text.trim(), 'booker_name': name.text.trim(), 'phone': phone.text.trim()}]);
      if (mounted) Navigator.pop(context, court);
      return;
    } on PostgrestException catch (e) {
      msg(e.code == '23505' ? 'Slot was just booked by someone else' : e.message);
      a = b = null; load();
    }
    if (mounted) setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New booking'),
    content: SizedBox(width: 560, child: SingleChildScrollView(child: Form(key: f, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SegmentedButton<String>(
        segments: [for (final e in courts.entries) ButtonSegment(value: e.key, label: Text(e.value))],
        selected: {court}, onSelectionChanged: (s) { court = s.first; a = b = null; load(); }),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today), label: Text(DateFormat('EEEE, d MMM yyyy').format(date)),
        onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2025), lastDate: DateTime.now().add(const Duration(days: 365)));
          if (d != null) { date = d; a = b = null; load(); }
        }),
      const SizedBox(height: 12),
      const Text('Pick hour(s) – tap a start and an end hour', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [for (var h = openH; h < closeH; h++) () {
        final t = taken(h), sel = a != null && h >= a! && h <= b!;
        return InkWell(onTap: off(h) ? null : () => tap(h), child: Container(
          width: 88, padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
            color: sel ? gold : t != null ? const Color(0xFF5A2330) : off(h) ? Colors.white10 : const Color(0xFF0F2A22)),
          child: Column(children: [
            Text(hl(h), style: TextStyle(fontWeight: FontWeight.bold, color: sel ? Colors.black : null)),
            Text(sel ? 'Selected' : t != null ? 'Booked' : off(h) ? 'Past' : 'Available', style: TextStyle(fontSize: 10, color: sel ? Colors.black : Colors.white70)),
          ])));
      }()]),
      if (a != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${hl(a!)} – ${hl(b! + 1)} (${b! - a! + 1} hour)', style: const TextStyle(color: gold, fontWeight: FontWeight.bold))),
      const SizedBox(height: 16),
      TextFormField(controller: sport, decoration: const InputDecoration(labelText: 'Sport (e.g. Futsal, Netball)'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
      const SizedBox(height: 10),
      TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.trim().isEmpty ? 'Required' : null),
      const SizedBox(height: 10),
      TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number'),
        validator: (v) => v!.replaceAll(RegExp(r'\D'), '').length < 9 ? 'Enter a valid phone number' : null),
    ])))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: saving ? null : submit, child: const Text('Book')),
    ],
  );
}
