import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfBlankoGenerator {
  static Future<Uint8List> buatBlanko({required String gedung}) async {
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
    } catch (e) {
      // Abaikan jika logo tidak ada
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 16),
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==========================================
              // HEADER KOP SURAT
              // ==========================================
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

              // ==========================================
              // INFO UMUM (KOSONG)
              // ==========================================
              pw.Text('Tanggal: ', style: textStyle), 
              pw.Text('Gedung: $gedung', style: textStyle),
              pw.SizedBox(height: 16),

              // ==========================================
              // TABEL A. SEBELUM (KOSONG)
              // ==========================================
              pw.Text('A. Pemeriksaan Sebelum Running Test', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _buildTabelBlanko(textStyle, [
                'Level Oli Mesin', 'Pemanas Oli', 'Air Radiator', 'Van Belt', 
                'Bahan Bakar/Solar', 'Level Air Accu', 'Battery Charger', 'Tegangan Battery'
              ]),
              pw.SizedBox(height: 16),

              // ==========================================
              // TABEL B. SAAT RUNNING (KOSONG)
              // ==========================================
              pw.Text('B. Pemeriksaan Saat Running Test', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _buildTabelBlanko(textStyle, [
                'Tegangan Output F/F', 'Tegangan Output F/N', 'Frekuensi', 'Cos Phi', 
                'Rpm Motor', 'Hour meter ON', 'Hour meter OFF', 'Temperatur Mesin', 
                'Temperatur Air Cooler', 'Temperatur Oli'
              ]),
              pw.SizedBox(height: 20),

              // ==========================================
              // PELAKSANA (TABEL TANPA GARIS)
              // ==========================================
              pw.Text('Pelaksana:', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(width: 0, color: PdfColors.white), // Tanpa garis
                columnWidths: {
                  0: const pw.FixedColumnWidth(180), // Kunci lebar label
                  1: const pw.FixedColumnWidth(10),  // Lebar titik dua
                  2: const pw.FlexColumnWidth(),     // Nama (kosong)
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Pelaksana 1', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(':', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(' ', style: textStyle)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Pelaksana 2', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(':', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(' ', style: textStyle)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Pelaksana 3', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(':', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(' ', style: textStyle)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Pelaksana 4', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(':', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(' ', style: textStyle)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Koordinator Pelaksana Fungsi', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(':', style: textStyle)),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(' ', style: textStyle)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // ==========================================
              // CATATAN (MINIMAL 2 BARIS KOSONG)
              // ==========================================
              pw.Text('Catatan:', style: textStyle.copyWith(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Table(
                columnWidths: {0: const pw.FlexColumnWidth()},
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 36), // Minimal 2 baris
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(' ', style: textStyle), // Kosong
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

  // ==========================================
  // HELPER UNTUK TABEL BLANKO
  // ==========================================
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