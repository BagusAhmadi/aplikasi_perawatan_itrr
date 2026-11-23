import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'genset_model.dart';

class PdfGenerator {
  static Future<Uint8List> buatPdf(GensetModel data) async {
    final doc = pw.Document();

    // 1. Memuat Font Times New Roman
    final fontData = await rootBundle.load('assets/fonts/TIMES.TTF');
    final ttf = pw.Font.ttf(fontData);
    
    // 2. Tema Font Standar
    final theme = pw.ThemeData.withFont(
      base: ttf,
      bold: ttf, 
    );
    final textStyle = pw.TextStyle(font: ttf, fontSize: 12);

    // Memuat Logo
    pw.ImageProvider? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {}

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 16), // Margin bawah dikurangi
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null) pw.Image(logoImage, width: 50, height: 50),
                  pw.SizedBox(width: 16),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BADAN RISET DAN INOVASI NASIONAL', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text('FORM PENGUJIAN GENSET TANPA BEBAN', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 12),

              // INFO
              pw.Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(data.tanggal)}', style: textStyle),
              pw.Text('Gedung: ${data.gedung}', style: textStyle),
              pw.SizedBox(height: 16),

              // TABEL A
              pw.Text('A. Pemeriksaan Sebelum Running Test', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Item', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Kondisi / Nilai', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                  ]),
                  ...data.radioSebelum.entries.map((e) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.key, style: textStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.value.toUpperCase(), style: textStyle)),
                  ])),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Battery Charger', style: textStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(data.angkaSaat['Battery Charger'] ?? '-', style: textStyle)),
                  ]),
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tegangan Battery', style: textStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(data.angkaSaat['Tegangan Battery'] ?? '-', style: textStyle)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 16),

              // TABEL B
              pw.Text('B. Pemeriksaan Saat Running Test', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Item', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nilai', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold))),
                  ]),
                  ...[
                    'Tegangan Output F/F', 'Tegangan Output F/N', 'Frekuensi', 'Cos Phi', 
                    'Rpm Motor', 'Hour meter ON', 'Hour meter OFF', 'Temperatur Mesin', 
                    'Temperatur Air Cooler', 'Temperatur Oli'
                  ].map((key) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(key, style: textStyle)),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(data.angkaSaat[key] ?? '-', style: textStyle)),
                  ])),
                ],
              ),
              pw.SizedBox(height: 24),

              // PELAKSANA
              pw.Text('Pelaksana:', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              ...data.pelaksana.asMap().entries.map((entry) {
                String nama = entry.value;
                if (nama.startsWith('Koordinator:')) {
                  nama = nama.replaceFirst('Koordinator:', '').trim();
                  return pw.Text('Koordinator Pelaksana Fungsi : $nama', style: textStyle);
                } else {
                  return pw.Text('Pelaksana ${entry.key + 1} : $nama', style: textStyle);
                }
              }),
              pw.SizedBox(height: 12),

              // CATATAN
              pw.Text('Catatan:', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              // Menggunakan Table agar kotak menyesuaikan panjang teks (default 2 baris)
              pw.Table(
                columnWidths: {0: const pw.FlexColumnWidth()},
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 36), // Setara 2 baris
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          data.catatan.isEmpty ? "-" : data.catatan, 
                          style: textStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}