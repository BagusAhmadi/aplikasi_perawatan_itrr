import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'genset_model.dart';

class PdfGenerator {
  static Future<Uint8List> buatPdf(GensetModel data) async {
    final doc = pw.Document();
    final formatter = DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID');
    final waktuCetak = '${formatter.format(DateTime.now())} WIB';

    // ==========================================
    // BAGIAN 1: MEMUAT LOGO (OPSIONAL)
    // ==========================================
    pw.ImageProvider? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Abaikan jika logo belum ada
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==========================================
              // BAGIAN 2: HEADER KOP SURAT
              // ==========================================
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null) pw.Image(logoImage, width: 50, height: 50),
                  pw.SizedBox(width: 16),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BADAN RISET DAN INOVASI NASIONAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('FORM PENGUJIAN GENSET TANPA BEBAN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 12),

              // ==========================================
              // BAGIAN 3: INFO UMUM
              // ==========================================
              pw.Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(data.tanggal)}'),
              pw.Text('Gedung: ${data.gedung}'),
              pw.SizedBox(height: 16),

              // ==========================================
              // BAGIAN 4: TABEL PEMERIKSAAN SEBELUM
              // ==========================================
              pw.Text('A. Pemeriksaan Sebelum Running Test', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Item')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Kondisi')),
                  ]),
                  ...data.radioSebelum.entries.map((e) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.key)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.value.toUpperCase())),
                  ])),
                ],
              ),
              pw.SizedBox(height: 16),

              // ==========================================
              // BAGIAN 5: TABEL PEMERIKSAAN SAAT RUNNING
              // ==========================================
              pw.Text('B. Pemeriksaan Saat Running Test', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Item')),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nilai')),
                  ]),
                  ...data.angkaSaat.entries.map((e) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.key)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.value)),
                  ])),
                ],
              ),
              pw.SizedBox(height: 24),

              // ==========================================
              // BAGIAN 6: PELAKSANA & CATATAN
              // ==========================================
              pw.Text('Pelaksana:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...data.pelaksana.map((p) => pw.Text('- $p')),
              pw.SizedBox(height: 12),
              pw.Text('Catatan: ${data.catatan.isEmpty ? "-" : data.catatan}'),

              pw.Spacer(),
              pw.Divider(),
              pw.Text('Dicetak pada: $waktuCetak', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}