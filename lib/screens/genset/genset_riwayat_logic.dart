import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'genset_model.dart';
import 'genset_database.dart';
import 'pdf_generator.dart';

class GensetRiwayatLogic {
  // ==========================================
  // FUNGSI LOAD DATA
  // ==========================================
  static Future<List<GensetModel>> loadData() async {
    return await GensetDatabase.bacaSemua();
  }

  // ==========================================
  // FUNGSI CETAK / SIMPAN PDF
  // ==========================================
  static Future<void> buatDanSimpanPdf(BuildContext context, GensetModel item, Function(bool) setLoading) async {
    setLoading(true);
    try {
      final Uint8List pdfBytes = await PdfGenerator.buatPdf(item);
      
      final Uri? outputUri = await FilePicker.saveFile(
        dialogTitle: 'Simpan PDF ke...',
        fileName: '${item.id}.pdf',
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      if (!context.mounted) return;
      setLoading(false);

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
      setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================================
  // FUNGSI HAPUS DATA
  // ==========================================
  static Future<bool> konfirmasiHapus(BuildContext context, GensetModel item) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data?'),
        content: Text('Data pengujian ${item.gedung} tanggal ${DateFormat('dd/MM/yyyy').format(item.tanggal)} akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await GensetDatabase.hapus(item.id);
      return true;
    }
    return false;
  }

  // ==========================================
  // FUNGSI EKSPOR DATABASE (LANGSUNG FILTER GEDUNG)
  // ==========================================
  static Future<void> mulaiEksporDatabase(
    BuildContext context, 
    VoidCallback onBerhasilEkspor, {
    required String filterGedung, // Wajib diisi dari halaman depan
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ekspor Data ${filterGedung.toUpperCase()}', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.all_inbox),
                  title: const Text('Semua Data'),
                  onTap: () { 
                    Navigator.pop(ctx); 
                    _prosesEkspor(
                      context, 
                      onBerhasilEkspor, 
                      gedungList: [filterGedung],
                    ); 
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Per Bulan'),
                  onTap: () async {
                    Navigator.pop(ctx); 
                    final picked = await showDatePicker(
                      context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030),
                      helpText: 'Pilih Bulan (Tanggal tidak penting)',
                    );
                    if (picked != null) {
                      _prosesEkspor(
                        context, 
                        onBerhasilEkspor, 
                        bulan: picked.month, 
                        tahun: picked.year,
                        gedungList: [filterGedung],
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Per Hari'),
                  onTap: () async {
                    Navigator.pop(ctx); 
                    final picked = await showDatePicker(
                      context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      _prosesEkspor(
                        context, 
                        onBerhasilEkspor, 
                        tanggal: picked,
                        gedungList: [filterGedung],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // PROSES EKSPOR (EKSEKUSI SQL)
  // ==========================================
  static Future<void> _prosesEkspor(BuildContext context, VoidCallback onBerhasilEkspor, {
    DateTime? tanggal, 
    int? bulan, 
    int? tahun, 
    required List<String> gedungList,
  }) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menyiapkan file database...')),
    );

    final file = await GensetDatabase.eksporDatabase(
      filterTanggal: tanggal,
      filterBulan: bulan,
      filterTahun: tahun,
      filterGedungList: gedungList,
    );

    if (file != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Backup Database Genset',
        ),
      );
      onBerhasilEkspor();
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data yang sesuai filter untuk diekspor.'), backgroundColor: Colors.red),
      );
    }
  }
}