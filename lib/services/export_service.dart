import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  /// Renders the widget wrapped by [key]'s RepaintBoundary to PNG bytes.
  static Future<Uint8List> capture(GlobalKey key) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static Future<void> savePng(Uint8List png, String fileName) async {
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: png,
      ext: 'png',
      mimeType: MimeType.png,
    );
  }

  static Future<void> savePdf(Uint8List png, String fileName) async {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final landscape = frame.image.width >= frame.image.height;

    final doc = pw.Document(title: fileName, author: 'JSP UiTM Kuala Terengganu');
    final img = pw.MemoryImage(png);
    final format = landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.zero,
        build: (ctx) => pw.Container(
          color: const PdfColor.fromInt(0xFF07080C),
          padding: const pw.EdgeInsets.all(18),
          child: pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
        ),
      ),
    );
    final bytes = await doc.save();
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}
