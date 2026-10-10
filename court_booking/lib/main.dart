import 'package:google_fonts/google_fonts.dart';
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
const bg = Color(0xFF05070F), card = Color(0xFF0D1326), card2 = Color(0xFF151D3A), line = Color(0xFF26325C);
const gold = Color(0xFFFFC21A), cyan = Color(0xFF00E5FF), okC = Color(0xFF2EE59D), busyC = Color(0xFFFF4D6D);
const courts = {'kolej': 'Court Kolej', 'kampus': 'Court Kampus'};
const openH = 8, closeH = 24;
ShapeBorder cut([double r = 14, Color? c]) => BeveledRectangleBorder(
    borderRadius: BorderRadius.only(topLeft: Radius.circular(r), bottomRight: Radius.circular(r)), side: BorderSide(color: c ?? line));
TextStyle hd([double s = 16, Color? c]) => GoogleFonts.chakraPetch(fontSize: s, fontWeight: FontWeight.w700, color: c, letterSpacing: .6);

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
      textTheme: GoogleFonts.chakraPetchTextTheme(ThemeData.dark().textTheme),
      colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark)
          .copyWith(primary: gold, onPrimary: Colors.black, secondary: cyan, surface: card, error: busyC),
      appBarTheme: const AppBarTheme(backgroundColor: card, surfaceTintColor: Colors.transparent),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: card2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: gold, width: 2))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 48), shape: cut(12, Colors.transparent), textStyle: hd(14))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48), side: const BorderSide(color: line))),
      segmentedButtonTheme: SegmentedButtonThemeData(style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(48, 48)),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? gold : card),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.black : Colors.white))),
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
  String? err; bool busy = false, hide = true;
  Future<void> go() async {
    setState(() { busy = true; err = null; });
    try { await db.auth.signInWithPassword(email: e.text.trim(), password: p.text); }
    on AuthException catch (x) { err = x.message; }
    if (mounted) setState(() => busy = false);
  }
  @override
  Widget build(BuildContext c) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(0, -.6), radius: 1.2, colors: [Color(0xFF14246B), bg])),
      child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: ShapeDecoration(color: card.withOpacity(.92), shape: cut(24, gold.withOpacity(.5)),
              shadows: [BoxShadow(color: gold.withOpacity(.15), blurRadius: 40)]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: gold.withOpacity(.35), blurRadius: 40)]),
                child: Image.asset('assets/logo.png', height: 120)),
            const SizedBox(height: 16),
            Text('COURT BOOKING', style: hd(26, gold)),
            const Text('JSP · UiTM Terengganu', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            TextField(controller: e, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email))),
            const SizedBox(height: 12),
            TextField(controller: p, obscureText: hide, onSubmitted: (_) => go(),
              decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(tooltip: hide ? 'Show password' : 'Hide password', icon: Icon(hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => hide = !hide)))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: busy ? null : go,
              icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.login),
              label: Text(busy ? 'SIGNING IN…' : 'LOG IN'))),
            if (err != null) Container(
              margin: const EdgeInsets.only(top: 14), padding: const EdgeInsets.all(10), width: double.infinity,
              decoration: BoxDecoration(color: busyC.withOpacity(.12), border: Border.all(color: busyC), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [const Icon(Icons.error_outline, color: busyC, size: 18), const SizedBox(width: 8), Expanded(child: Text(err!))])),
            const SizedBox(height: 10),
            const Text('Committee accounts only', style: TextStyle(fontSize: 12, color: Colors.white54)),
          ]),
        ))))),
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

  Widget legend() => Wrap(spacing: 14, runSpacing: 4, children: [
    for (final l in <List<Object>>[[Icons.check_circle_outline, 'Available', okC], [Icons.lock_outline, 'Booked', busyC], [Icons.check_circle, 'Selected', gold], [Icons.schedule, 'Past', Colors.white38]])
      Row(mainAxisSize: MainAxisSize.min, children: [Icon(l[0] as IconData, size: 14, color: l[2] as Color), const SizedBox(width: 4), Text(l[1] as String, style: const TextStyle(fontSize: 12, color: Colors.white70))])]);

  Widget box(Widget ch, Color col, double w, {VoidCallback? tap, Color? bd, String? tip}) {
    final m = Padding(padding: const EdgeInsets.all(2), child: Material(
      color: col, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: bd ?? Colors.transparent)),
      child: InkWell(borderRadius: BorderRadius.circular(8), onTap: tap, child: SizedBox(width: w, height: 52, child: Center(child: ch)))));
    return tip == null ? m : Tooltip(message: tip, child: m);
  }

  Widget weekGrid(double w) {
    final ix = idx, now = DateTime.now(), today = dOnly(now);
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    return Column(children: [
      Row(children: [
        box(const Text(''), Colors.transparent, 64),
        for (final d in days) box(Column(mainAxisSize: MainAxisSize.min, children: [
          Text(DateFormat('EEE').format(d).toUpperCase(), style: hd(13, d == today ? gold : null)),
          Text(DateFormat('d MMM').format(d), style: TextStyle(fontSize: 12, color: d == today ? gold : Colors.white70))]),
          card2, w, bd: d == today ? gold : line),
      ]),
      for (var h = openH; h < closeH; h++) Row(children: [
        box(Text(hl(h), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: h == now.hour ? gold : Colors.white70)), Colors.transparent, 64),
        for (final d in days) () {
          final s = ix['${ymd(d)}|$h'];
          final past = d.isBefore(today) || (d == today && h < now.hour);
          if (s != null) {
            return box(Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.lock_outline, size: 12, color: busyC), const SizedBox(width: 3),
                Flexible(child: Text(s.sport, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))]),
              Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white70))]),
              const Color(0xFF3A1020), w, bd: busyC.withOpacity(.55), tap: () => detail(s), tip: '${s.sport} · ${s.name} · ${s.phone}');
          }
          if (past) return box(const Icon(Icons.schedule, size: 14, color: Colors.white24), card, w);
          return box(const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_outline, size: 14, color: okC), SizedBox(width: 4), Text('Free', style: TextStyle(fontSize: 12, color: okC))]),
              const Color(0xFF0A2620), w, bd: okC.withOpacity(.3), tap: () => book(d: d, h: h), tip: 'Book ${hl(h)}, ${DateFormat('EEE d MMM').format(d)}');
        }(),
      ]),
    ]);
  }

  Widget monthGrid(double w) {
    final off = start.weekday - 1, n = end.day, rows = ((off + n) / 7).ceil(), today = dOnly(DateTime.now());
    Widget cell(int r, int c) {
      final day = r * 7 + c - off + 1;
      if (day < 1 || day > n) return SizedBox(width: w + 4, height: 102);
      final d = DateTime(start.year, start.month, day);
      final ss = slots.where((s) => s.date == d).toList();
      final pct = ss.length / (closeH - openH);
      return Padding(padding: const EdgeInsets.all(2), child: Material(
        color: card2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: d == today ? gold : line)),
        child: InkWell(borderRadius: BorderRadius.circular(10), onTap: () { month = false; focus = d; load(); },
          child: Container(width: w, height: 98, padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$day', style: hd(16, d == today ? gold : null)),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(minHeight: 5, value: pct, backgroundColor: Colors.white12, color: pct >= 1 ? busyC : pct > .5 ? Colors.orange : okC)),
            const SizedBox(height: 4),
            Text('${ss.length}/${closeH - openH} h booked', style: const TextStyle(fontSize: 11)),
            Text(ss.map((s) => s.sport).toSet().take(2).join(', '), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ])))));
    }
    return Column(children: [
      Row(children: [for (final d in ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']) SizedBox(width: w + 4, height: 28, child: Center(child: Text(d, style: hd(12, cyan))))]),
      for (var r = 0; r < rows; r++) Row(children: [for (var c = 0; c < 7; c++) cell(r, c)]),
    ]);
  }

  Widget stat(IconData i, String l, String v, Color c) => Expanded(child: Container(
    margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(12), decoration: ShapeDecoration(color: card, shape: cut(12)),
    child: Row(children: [Icon(i, color: c), const SizedBox(width: 10), Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(v, style: hd(20, c)), Text(l, style: const TextStyle(fontSize: 12, color: Colors.white70))]))])));

  Widget courtCard(String k, IconData ic) {
    final sel = court == k;
    return Expanded(child: Padding(padding: const EdgeInsets.all(4), child: Material(
      color: sel ? const Color(0xFF2A2208) : card, shape: cut(14, sel ? gold : line),
      child: InkWell(customBorder: cut(14), onTap: () { court = k; load(); },
        child: Container(height: 64, padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(boxShadow: sel ? [BoxShadow(color: gold.withOpacity(.22), blurRadius: 18)] : null),
          child: Row(children: [Icon(ic, color: sel ? gold : Colors.white54, size: 28), const SizedBox(width: 10),
            Expanded(child: Text(courts[k]!, style: hd(15, sel ? gold : Colors.white70))),
            if (sel) const Icon(Icons.check_circle, color: gold, size: 18)]))))));
  }

  @override
  Widget build(BuildContext context) {
    final total = (closeH - openH) * (month ? end.day : 7), bk = slots.length;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Row(children: [Image.asset('assets/logo.png', height: 44), const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('COURT BOOKING', style: hd(18, gold)), const Text('JSP · UiTM Terengganu', style: TextStyle(fontSize: 12, color: Colors.white70))])]),
        actions: [IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout), onPressed: () => db.auth.signOut())],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(2), child: Container(height: 2,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [gold, cyan, Colors.transparent])))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => book(), backgroundColor: gold, foregroundColor: Colors.black, shape: cut(14, gold),
        icon: const Icon(Icons.add), label: Text('NEW BOOKING', style: hd(14, Colors.black))),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1400), child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: Column(children: [
            Row(children: [courtCard('kolej', Icons.sports_basketball), courtCard('kampus', Icons.stadium)]),
            Row(children: [
              stat(Icons.check_circle_outline, 'Hours available', '${total - bk}', okC),
              stat(Icons.lock_outline, 'Hours booked', '$bk', busyC),
              stat(Icons.speed, 'Utilisation', '${(bk * 100 / total).round()}%', gold)]),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SegmentedButton<bool>(
                segments: const [ButtonSegment(value: false, label: Text('Week')), ButtonSegment(value: true, label: Text('Month'))],
                selected: {month}, onSelectionChanged: (s) { month = s.first; load(); }),
              IconButton(tooltip: 'Previous', onPressed: () => move(-1), icon: const Icon(Icons.chevron_left)),
              IconButton(tooltip: 'Next', onPressed: () => move(1), icon: const Icon(Icons.chevron_right)),
              OutlinedButton.icon(onPressed: () { focus = dOnly(DateTime.now()); load(); }, icon: const Icon(Icons.today), label: const Text('Today')),
              OutlinedButton.icon(onPressed: () => save(png: true), icon: const Icon(Icons.image_outlined), label: const Text('PNG')),
              OutlinedButton.icon(onPressed: save, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('PDF')),
            ])),
          ])),
          if (busy) const LinearProgressIndicator(color: gold, minHeight: 3),
          LayoutBuilder(builder: (_, bc) {
            final w = max(month ? 100.0 : 104.0, (bc.maxWidth - (month ? 40 : 110)) / 7);
            return SingleChildScrollView(scrollDirection: Axis.horizontal, child: RepaintBoundary(key: key,
              child: Container(color: bg, padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title.toUpperCase(), style: hd(20, gold)),
                const SizedBox(height: 4), legend(), const SizedBox(height: 10),
                month ? monthGrid(w) : weekGrid(w),
              ]))));
          }),
        ]),
      ))),
    );
  }
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

  Widget sec(int n, String t) => Padding(padding: const EdgeInsets.only(top: 18, bottom: 8), child: Row(children: [
    CircleAvatar(radius: 12, backgroundColor: gold, child: Text('$n', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
    const SizedBox(width: 10), Text(t, style: hd(15))]));

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: card, insetPadding: const EdgeInsets.all(12), shape: cut(20, gold.withOpacity(.6)),
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 620), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1B2A6B), card])),
        child: Row(children: [const Icon(Icons.sports_score, color: gold), const SizedBox(width: 10), Text('NEW BOOKING', style: hd(20, gold))])),
      Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: Form(key: f, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sec(1, 'Court & date'),
        SegmentedButton<String>(
          segments: [for (final e in courts.entries) ButtonSegment(value: e.key, label: Text(e.value))],
          selected: {court}, onSelectionChanged: (s) { court = s.first; a = b = null; load(); }),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today), label: Text(DateFormat('EEEE, d MMM yyyy').format(date)),
          onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2025), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (d != null) { date = d; a = b = null; load(); }
          }),
        sec(2, 'Time · tap the start hour, then the end hour'),
        Wrap(spacing: 6, runSpacing: 6, children: [for (var h = openH; h < closeH; h++) () {
          final t = taken(h), sel = a != null && h >= a! && h <= b!;
          final fg = sel ? Colors.black : t != null ? busyC : off(h) ? Colors.white38 : okC;
          return InkWell(borderRadius: BorderRadius.circular(10), onTap: off(h) ? null : () => tap(h), child: Container(
            width: 92, height: 56,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? gold : fg.withOpacity(.4)),
              color: sel ? gold : t != null ? const Color(0xFF3A1020) : off(h) ? Colors.white10 : const Color(0xFF0A2620)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(hl(h), style: hd(14, fg)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(sel ? Icons.check_circle : t != null ? Icons.lock_outline : off(h) ? Icons.schedule : Icons.check_circle_outline, size: 12, color: fg),
                const SizedBox(width: 3),
                Text(sel ? 'Selected' : t != null ? 'Booked' : off(h) ? 'Past' : 'Free', style: TextStyle(fontSize: 11, color: fg))]),
            ])));
        }()]),
        sec(3, 'Booker details'),
        Wrap(spacing: 6, children: [for (final x in ['Futsal', 'Basketball', 'Netball', 'Handball', 'Volleyball', 'Badminton'])
          ActionChip(label: Text(x), onPressed: () => setState(() => sport.text = x))]),
        const SizedBox(height: 10),
        TextFormField(controller: sport, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Sport / activity', prefixIcon: Icon(Icons.sports)), validator: (v) => v!.trim().isEmpty ? 'Please enter the sport' : null),
        const SizedBox(height: 12),
        TextFormField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v!.trim().isEmpty ? 'Please enter a name' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', hintText: 'e.g. 0123456789', prefixIcon: Icon(Icons.phone_outlined)),
          validator: (v) => v!.replaceAll(RegExp(r'\D'), '').length < 9 ? 'Enter a valid phone number' : null),
      ])))),
      Container(padding: const EdgeInsets.all(14), decoration: const BoxDecoration(border: Border(top: BorderSide(color: line))), child: Row(children: [
        Expanded(child: Text(a == null ? 'Select a time to continue' : '${courts[court]} · ${DateFormat('EEE d MMM').format(date)} · ${hl(a!)} – ${hl(b! + 1)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: a == null ? Colors.white60 : gold))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: saving ? null : submit,
          icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.check),
          label: const Text('CONFIRM')),
      ])),
    ])),
  );
}
