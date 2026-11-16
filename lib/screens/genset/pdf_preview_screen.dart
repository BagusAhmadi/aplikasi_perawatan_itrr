import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Pratinjau PDF'),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        // MENAMBAHKAN TOMBOL CETAK DAN BAGIKAN DI POJOK KANAN ATAS
        actions: [
          // Tombol Cetak
          TextButton.icon(
            onPressed: () async {
              await Printing.layoutPdf(
                onLayout: (format) async => pdfBytes,
                name: fileName,
              );
            },
            icon: const Icon(Icons.print, color: Colors.white, size: 20),
            label: const Text('Cetak PDF', style: TextStyle(color: Colors.white)),
          ),
          
          // Tombol Bagikan
          TextButton.icon(
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: fileName,
              );
            },
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            label: const Text('Bagikan PDF', style: TextStyle(color: Colors.white)),
          ),
          
          const SizedBox(width: 8), // Jarak sedikit dari ujung kanan
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: fileName,
        // Menghilangkan action bar bawaan agar tidak dobel
        actions: [], 
      ),
    );
  }
}