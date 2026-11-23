import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfBlankoGenerator {
  static Future<Uint8List> buatBlanko({required String gedung}) async {
    final doc = pw.Document();

    // Memuat Font
    final fontData = await rootBundle.load('assets/fonts/TIMES.TTF');
    final ttf = pw.Font.ttf(fontData);
    final theme = pw.ThemeData.withFont(base: ttf, bold: ttf);
    final textStyle = pw.TextStyle(font: ttf, fontSize: 12);

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
              pw.Text('Tanggal: ', style: textStyle), 
              pw.Text('Gedung: $gedung', style: textStyle),
              pw.SizedBox(height: 16),

              // TABEL A
              pw.Text('A. Pemeriksaan Sebelum Running Test', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _buildTabelBlanko(textStyle, [
                'Level Oli Mesin', 'Pemanas Oli', 'Air Radiator', 'Van Belt', 
                'Bahan Bakar/Solar', 'Level Air Accu', 'Battery Charger', 'Tegangan Battery'
              ]),
              pw.SizedBox(height: 16),

              // TABEL B
              pw.Text('B. Pemeriksaan Saat Running Test', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _buildTabelBlanko(textStyle, [
                'Tegangan Output F/F', 'Tegangan Output F/N', 'Frekuensi', 'Cos Phi', 
                'Rpm Motor', 'Hour meter ON', 'Hour meter OFF', 'Temperatur Mesin', 
                'Temperatur Air Cooler', 'Temperatur Oli'
              ]),
              pw.SizedBox(height: 20),

              // PELAKSANA
              pw.Text('Pelaksana:', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.Text('Pelaksana 1 : ', style: textStyle), 
              pw.Text('Pelaksana 2 : ', style: textStyle), 
              pw.Text('Pelaksana 3 : ', style: textStyle), 
              pw.Text('Pelaksana 4 : ', style: textStyle), 
              pw.SizedBox(height: 8),
              pw.Text('Koordinator Pelaksana Fungsi : ', style: textStyle), 
              pw.SizedBox(height: 12),

              // CATATAN (Kosong 2 Baris)
              pw.Text('Catatan:', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Table(
                columnWidths: {0: const pw.FlexColumnWidth()},
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 36), // 2 Baris kosong
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(' ', style: textStyle),
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

  static pw.Widget _buildTabelBlanko(pw.TextStyle style, List<String> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Item', style: style.copyWith(fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Kondisi / Nilai', style: style.copyWith(fontWeight: pw.FontWeight.bold))),
        ]),
        ...items.map((e) => pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e, style: style)),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(' ', style: style)), 
        ])),
      ],
    );
  }
}