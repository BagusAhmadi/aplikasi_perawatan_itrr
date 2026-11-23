import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfBlankoGenerator {
  static Future<Uint8List> buatBlanko({required String gedung}) async {
    final doc = pw.Document();
    final formatter = DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID');
    final waktuCetak = '${formatter.format(DateTime.now())} WIB';

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
        margin: const pw.EdgeInsets.all(32),
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
                      pw.Text('BADAN RISET DAN INOVASI NASIONAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('FORM PENGUJIAN GENSET TANPA BEBAN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10), // Dikurangi dari 12

              // ==========================================
              // INFO UMUM (KOSONG)
              // ==========================================
              pw.Text('Tanggal: ', style: const pw.TextStyle(fontSize: 11)), 
              pw.Text('Gedung: $gedung', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 12), // Dikurangi dari 16

              // ==========================================
              // TABEL A. SEBELUM (KOSONG)
              // ==========================================
              pw.Text('A. Pemeriksaan Sebelum Running Test', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6), // Dikurangi dari 8
              _buildTabelBlanko(
                items: [
                  'Level Oli Mesin', 'Pemanas Oli', 'Air Radiator', 'Van Belt', 
                  'Bahan Bakar/Solar', 'Level Air Accu', 'Battery Charger', 'Tegangan Battery'
                ],
              ),
              pw.SizedBox(height: 12), // Dikurangi dari 16

              // ==========================================
              // TABEL B. SAAT RUNNING (KOSONG)
              // ==========================================
              pw.Text('B. Pemeriksaan Saat Running Test', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6), // Dikurangi dari 8
              _buildTabelBlanko(
                items: [
                  'Tegangan Output F/F', 'Tegangan Output F/N', 'Frekuensi', 'Cos Phi', 
                  'Rpm Motor', 'Hour meter ON', 'Hour meter OFF', 'Temperatur Mesin', 
                  'Temperatur Air Cooler', 'Temperatur Oli'
                ],
              ),
              pw.SizedBox(height: 16), // Dikurangi dari 24

              // ==========================================
              // PELAKSANA & CATATAN (KOSONG)
              // ==========================================
              pw.Text('Pelaksana:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text('Pelaksana 1 : ', style: const pw.TextStyle(fontSize: 11)), 
              pw.Text('Pelaksana 2 : ', style: const pw.TextStyle(fontSize: 11)), 
              pw.Text('Pelaksana 3 : ', style: const pw.TextStyle(fontSize: 11)), 
              pw.Text('Pelaksana 4 : ', style: const pw.TextStyle(fontSize: 11)), 
              pw.SizedBox(height: 8),
              pw.Text('Koordinator Pelaksana Fungsi : ', style: const pw.TextStyle(fontSize: 11)), 
              pw.SizedBox(height: 8),
              pw.Text('Catatan: ', style: const pw.TextStyle(fontSize: 11)),
              
              // Menghapus pw.Spacer() agar tidak mendorong teks keluar halaman
              
              pw.Divider(),
              pw.Text('Dicetak pada: $waktuCetak', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // Fungsi bantuan untuk membuat tabel dengan nilai kosong
  static pw.Widget _buildTabelBlanko({required List<String> items}) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header Tabel
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Item', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Kondisi / Nilai', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
        ]),
        // Isi Tabel (Baris demi baris kosong)
        ...items.map((e) => pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e, style: const pw.TextStyle(fontSize: 10))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(' ', style: const pw.TextStyle(fontSize: 10))), 
        ])),
      ],
    );
  }
}