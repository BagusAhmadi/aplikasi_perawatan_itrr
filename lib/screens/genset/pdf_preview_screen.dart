import 'dart:typed_data';
import 'package:file_picker/file_picker.dart'; // <-- Tambahkan import ini
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

  // ==========================================
  // FUNGSI SIMPAN PDF (Pakai File Picker)
  // ==========================================
  Future<void> _simpanPdf(BuildContext context) async {
    try {
      final Uri? outputUri = await FilePicker.saveFile(
        dialogTitle: 'Simpan PDF ke...',
        fileName: fileName,
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      if (!context.mounted) return;
      
      if (outputUri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF berhasil disimpan: $outputUri')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penyimpanan dibatalkan')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Pratinjau PDF'),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        actions: [
          // 1. Ganti Teks Menjadi "Simpan PDF" dan panggil fungsi _simpanPdf
          TextButton.icon(
            onPressed: () => _simpanPdf(context),
            icon: const Icon(Icons.save_alt, color: Colors.white, size: 20), // Ikon diganti simpan
            label: const Text('Simpan PDF', style: TextStyle(color: Colors.white)),
          ),
          
          // 2. Tombol Bagikan Tetap Sama
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
          
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          PdfPreview(
            build: (format) => pdfBytes,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: fileName,
            actions: [], 
          ),
          
          // Menutupi bar bawah bawaan PdfPreview
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 50, 
              color: Colors.grey[200], 
            ),
          ),
        ],
      ),
    );
  }
}