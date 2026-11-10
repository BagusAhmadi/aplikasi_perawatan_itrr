import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/accordion_section.dart';
import '../../widgets/form_inputs.dart';
import 'genset_model.dart';
import 'genset_database.dart';      // Import Database SQLite
import 'pdf_generator.dart';
import 'genset_pelaksana_section.dart'; // Import widget yang dipisah

class GensetFormScreen extends StatefulWidget {
  const GensetFormScreen({super.key});

  @override
  State<GensetFormScreen> createState() => _GensetFormScreenState();
}

class _GensetFormScreenState extends State<GensetFormScreen> {
  // ==========================================
  // BAGIAN 1: STATE / VARIABEL DATA FORM
  // ==========================================
  String _pilihanTanggal = 'hari_ini';
  DateTime _tanggalTerpilih = DateTime.now();
  String _pilihanGedung = 'gedung_11';
  String? _expandedForm;

  final Map<String, String> _radioValues = {
    'Level Oli Mesin': 'baik',
    'Pemanas Oli': 'baik',
    'Air Radiator': 'baik',
    'Van Belt': 'baik',
    'Bahan Bakar/Solar': 'baik',
    'Level Air Accu': 'baik',
  };

  final Map<String, String> _angkaValues = {
    'Battery Charger': '', 
    'Tegangan Battery': '',
    'Tegangan Output F/F': '', 'Tegangan Output F/N': '',
    'Frekuensi': '', 'Cos Phi': '', 'Rpm Motor': '',
    'Hour meter ON': '', 'Hour meter OFF': '',
    'Temperatur Mesin': '', 'Temperatur Air Cooler': '', 'Temperatur Oli': '',
  };

  final List<TextEditingController> _pelaksanaControllers = List.generate(4, (index) => TextEditingController());
  final TextEditingController _koordinatorController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    for (var c in _pelaksanaControllers) { c.dispose(); }
    _koordinatorController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _toggleForm(String id) {
    setState(() => _expandedForm = _expandedForm == id ? null : id);
  }

  // ==========================================
  // BAGIAN 2: AMBIL HOUR METER OFF TERAKHIR (SQL)
  // ==========================================
  Future<void> _ambilHourMeterOffTerakhir() async {
    // Memanggil fungsi dari GensetDatabase
    final hourOffTerakhir = await GensetDatabase.getHourMeterOffTerakhir();

    if (hourOffTerakhir != null) {
      setState(() {
        _angkaValues['Hour meter ON'] = hourOffTerakhir;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hour meter ON diisi otomatis: $hourOffTerakhir')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada data Hour meter OFF sebelumnya.'), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================================
  // BAGIAN 3: LOGIKA SIMPAN DATA KE SQLITE
  // ==========================================
  Future<void> _simpanData() async {
    final tanggalSimpan = _pilihanTanggal == 'hari_ini' ? DateTime.now() : _tanggalTerpilih;
    final idFile = 'Genset_${_pilihanGedung}_${DateFormat('yyyy-MM-dd').format(tanggalSimpan)}';

    // Cek duplikasi lewat Database (bukan File JSON lagi)
    final isExist = await GensetDatabase.cekIdExists(idFile);
    if (isExist) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gagal Menyimpan'),
          content: Text('Data untuk ${_pilihanGedung.replaceAll('_', ' ')} pada tanggal ${DateFormat('dd/MM/yyyy').format(tanggalSimpan)} sudah ada.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      List<String> daftarPelaksana = _pelaksanaControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
      if (_koordinatorController.text.trim().isNotEmpty) {
        daftarPelaksana.add('Koordinator: ${_koordinatorController.text.trim()}');
      }

      final dataBaru = GensetModel(
        id: idFile,
        tanggal: tanggalSimpan,
        gedung: _pilihanGedung.replaceAll('_', ' '),
        radioSebelum: _radioValues,
        angkaSaat: _angkaValues,
        pelaksana: daftarPelaksana,
        catatan: _catatanController.text.trim(),
      );

      // Simpan ke SQLite
      await GensetDatabase.simpan(dataBaru);
      
      if (!mounted) return;
      setState(() => _isSaving = false);

      // Generate PDF untuk ditawarkan dibagikan
      final pdfBytes = await PdfGenerator.buatPdf(dataBaru);
      if (!mounted) return;
      _tampilkanDialogBerhasil(dataBaru, pdfBytes);

    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // ==========================================
  // BAGIAN 4: DIALOG BERHASIL & BAGIKAN PDF + JSON
  // ==========================================
  void _tampilkanDialogBerhasil(GensetModel dataBaru, Uint8List pdfBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Berhasil Disimpan'),
        content: const Text('Data berhasil disimpan. Bagikan file PDF dan JSON sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final tempDir = await getTemporaryDirectory();
              
              final tempPdf = File('${tempDir.path}/${dataBaru.id}.pdf');
              await tempPdf.writeAsBytes(pdfBytes);
              
              final tempJson = File('${tempDir.path}/${dataBaru.id}.json');
              await tempJson.writeAsString(jsonEncode(dataBaru.toJson()));
              
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(tempPdf.path), XFile(tempJson.path)],
                  text: 'Laporan Genset (PDF & JSON)',
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Ya, Bagikan'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BAGIAN 5: TAMPILAN UI (BUILD)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- SECTION TANGGAL ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PILIH TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                RadioListTile<String>(
                  title: const Text('Hari Ini', style: TextStyle(fontSize: 14)),
                  value: 'hari_ini', groupValue: _pilihanTanggal, activeColor: const Color(0xFF3F51B5), contentPadding: EdgeInsets.zero, dense: true,
                  onChanged: (val) => setState(() => _pilihanTanggal = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Bukan Hari Ini', style: TextStyle(fontSize: 14)),
                  value: 'bukan_hari_ini', groupValue: _pilihanTanggal, activeColor: const Color(0xFF3F51B5), contentPadding: EdgeInsets.zero, dense: true,
                  onChanged: (val) => setState(() => _pilihanTanggal = val!),
                ),
                if (_pilihanTanggal == 'bukan_hari_ini')
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context, initialDate: _tanggalTerpilih, firstDate: DateTime(2020), lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _tanggalTerpilih = picked);
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(_tanggalTerpilih)}'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- SECTION GEDUNG ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PILIH GEDUNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Gedung 11', style: TextStyle(fontSize: 14)),
                        value: 'gedung_11', groupValue: _pilihanGedung, activeColor: const Color(0xFF3F51B5), contentPadding: EdgeInsets.zero, dense: true,
                        onChanged: (val) => setState(() => _pilihanGedung = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Gedung 13', style: TextStyle(fontSize: 14)),
                        value: 'gedung_13', groupValue: _pilihanGedung, activeColor: const Color(0xFF3F51B5), contentPadding: EdgeInsets.zero, dense: true,
                        onChanged: (val) => setState(() => _pilihanGedung = val!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- ACCORDION SEBELUM RUNNING ---
          AccordionSection(
            title: 'Pemeriksaan Sebelum Running Test Genset',
            isExpanded: _expandedForm == 'sebelum',
            onToggle: () => _toggleForm('sebelum'),
            isInnerAccordion: true,
            child: Column(
              children: [
                ..._radioValues.keys.map((key) => CustomRadioRow(
                  label: key,
                  groupValue: _radioValues[key]!,
                  onChanged: (val) => setState(() => _radioValues[key] = val!),
                )),
                CustomNumberField(
                  label: 'Battery Charger',
                  initialValue: _angkaValues['Battery Charger'],
                  onChanged: (val) => _angkaValues['Battery Charger'] = val,
                ),
                CustomNumberField(
                  label: 'Tegangan Battery',
                  initialValue: _angkaValues['Tegangan Battery'],
                  onChanged: (val) => _angkaValues['Tegangan Battery'] = val,
                ),
              ],
            ),
          ),

          // --- ACCORDION SAAT RUNNING ---
          AccordionSection(
            title: 'Pemeriksaan Saat Running Test Genset',
            isExpanded: _expandedForm == 'saat',
            onToggle: () => _toggleForm('saat'),
            isInnerAccordion: true,
            child: Column(
              children: [
                // Deret input pertama
                ...['Tegangan Output F/F', 'Tegangan Output F/N', 'Frekuensi', 'Cos Phi', 
                'Rpm Motor'].map((key) => CustomNumberField(
                  label: key,
                  initialValue: _angkaValues[key],
                  onChanged: (val) => _angkaValues[key] = val,
                )),
                
                // Input Hour meter ON dengan tombol
                CustomNumberField(
                  label: 'Hour meter ON',
                  initialValue: _angkaValues['Hour meter ON'],
                  onChanged: (val) => _angkaValues['Hour meter ON'] = val,
                  bottomWidget: TextButton.icon(
                    onPressed: _ambilHourMeterOffTerakhir,
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Ambil dari Hour meter OFF terakhir', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3F51B5),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),

                // Input Hour meter OFF
                CustomNumberField(
                  label: 'Hour meter OFF',
                  initialValue: _angkaValues['Hour meter OFF'],
                  onChanged: (val) => _angkaValues['Hour meter OFF'] = val,
                ),
                
                // Deret input Temperatur
                ...['Temperatur Mesin', 'Temperatur Air Cooler', 'Temperatur Oli']
                .map((key) => CustomNumberField(
                  label: key, 
                  initialValue: _angkaValues[key],
                  onChanged: (val) => _angkaValues[key] = val,
                )).toList(),
              ],
            ),
          ),

          // --- SECTION PELAKSANA & CATATAN (File Terpisah) ---
          GensetPelaksanaSection(
            pelaksanaControllers: _pelaksanaControllers,
            koordinatorController: _koordinatorController,
            catatanController: _catatanController,
          ),

          // --- TOMBOL SIMPAN ---
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _simpanData,
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan ke Riwayat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}