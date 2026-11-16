import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'genset_model.dart';
import 'genset_database.dart';
import 'pdf_generator.dart';

class GensetRiwayatLogic {
  // --- FUNGSI LOAD DATA ---
  static Future<List<GensetModel>> loadData() async {
    return await GensetDatabase.bacaSemua();
  }

  // --- FUNGSI CETAK PDF ---
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
        SnackBar(content: Text('Gagal mencetak PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- FUNGSI HAPUS DATA ---
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

  // --- ALUR EKSPOR DATABASE ---
  static Future<void> mulaiEksporDatabase(BuildContext context, VoidCallback onBerhasilEkspor) async {
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
                const Text('Pilih Waktu Ekspor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.all_inbox),
                  title: const Text('Semua Data'),
                  onTap: () { Navigator.pop(ctx); _pilihGedungEkspor(context, onBerhasilEkspor); },
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
                    if (picked != null) _pilihGedungEkspor(context, onBerhasilEkspor, bulan: picked.month, tahun: picked.year);
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
                    if (picked != null) _pilihGedungEkspor(context, onBerhasilEkspor, tanggal: picked);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _pilihGedungEkspor(BuildContext context, VoidCallback onBerhasilEkspor, {DateTime? tanggal, int? bulan, int? tahun}) async {
    bool pilihGedung11 = true;
    bool pilihGedung13 = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Pilih Gedung'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Gedung 11'),
                    value: pilihGedung11,
                    onChanged: (val) => setStateDialog(() => pilihGedung11 = val!),
                  ),
                  CheckboxListTile(
                    title: const Text('Gedung 13'),
                    value: pilihGedung13,
                    onChanged: (val) => setStateDialog(() => pilihGedung13 = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text('Batal')
                ),
                ElevatedButton(
                  onPressed: () {
                    List<String> gedungTerpilih = [];
                    if (pilihGedung11) gedungTerpilih.add('gedung 11');
                    if (pilihGedung13) gedungTerpilih.add('gedung 13');

                    if (gedungTerpilih.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih minimal satu gedung!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    _prosesEkspor(context, onBerhasilEkspor, 
                      tanggal: tanggal,
                      bulan: bulan,
                      tahun: tahun,
                      gedungList: gedungTerpilih,
                    );
                  },
                  child: const Text('Ekspor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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