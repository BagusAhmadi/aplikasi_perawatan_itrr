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
      appBar: AppBar(
        title: const Text('Pratinjau PDF'),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),
      // PdfPreview akan otomatis membuatkan tombol Bagikan (Share) & Cetak (Print)
      // di bagian bawah atau atas (tergantung platform)
      body: PdfPreview(
        build: (format) => pdfBytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: fileName,
        // Menyesuaikan tampilan action bar di dalam PdfPreview
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.share),
            onPressed: (context, build, pageFormat) async {
              final bytes = await build(pageFormat);
              await Printing.sharePdf(
                bytes: bytes, 
                filename: fileName
              );
            },
          ),
          PdfPreviewAction(
            icon: const Icon(Icons.print),
            onPressed: (context, build, pageFormat) async {
              final bytes = await build(pageFormat);
              await Printing.layoutPdf(
                onLayout: (format) async => bytes,
                name: fileName,
              );
            },
          ),
        ],
      ),
    );
  }
}