import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/accordion_section.dart';
import '../../widgets/form_inputs.dart';
import 'genset_model.dart';
import 'pdf_generator.dart';

class GensetFormScreen extends StatefulWidget {
  final GensetModel? dataEdit;
  const GensetFormScreen({super.key, this.dataEdit});

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
    'Tegangan Battery': '', // Typo sudah diperbaiki
    'Tegangan Output F/F': '', 'Tegangan Output F/N': '',
    'Frekuensi': '', 'Cos Phi': '', 'Rpm Motor': '',
    'Hour meter ON': '', 'Hour meter OFF': '',
    'Temperatur Mesin': '', 'Temperatur Air Cooler': '', 'Temperatur Oli': '',
  };

  final List<TextEditingController> _pelaksanaControllers = List.generate(4, (index) => TextEditingController());
  final TextEditingController _koordinatorController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  bool _isSaving = false;

  // ==========================================
  // BAGIAN 2: INISIALISASI (LOAD DATA EDIT)
  // ==========================================
  @override
  void initState() {
    super.initState();
    if (widget.dataEdit != null) {
      _pilihanGedung = widget.dataEdit!.gedung.replaceAll(' ', '_');
      _tanggalTerpilih = widget.dataEdit!.tanggal;
      _pilihanTanggal = 'bukan_hari_ini';

      _radioValues.addAll(widget.dataEdit!.radioSebelum);
      _angkaValues.addAll(widget.dataEdit!.angkaSaat);

      for (int i = 0; i < widget.dataEdit!.pelaksana.length && i < 4; i++) {
        _pelaksanaControllers[i].text = widget.dataEdit!.pelaksana[i];
      }
      _catatanController.text = widget.dataEdit!.catatan;
    }
  }

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
  // BAGIAN 3: LOGIKA SIMPAN DATA
  // ==========================================
  Future<void> _simpanData() async {
    final tanggalSimpan = _pilihanTanggal == 'hari_ini' ? DateTime.now() : _tanggalTerpilih;
    final idFile = 'Genset_${_pilihanGedung}_${DateFormat('yyyy-MM-dd').format(tanggalSimpan)}';

    if (widget.dataEdit == null) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$idFile.json');
      if (file.existsSync()) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Gagal Menyimpan'),
            content: Text('Data pengujian untuk ${_pilihanGedung.replaceAll('_', ' ')} pada tanggal ${DateFormat('dd/MM/yyyy').format(tanggalSimpan)} sudah ada.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
        return;
      }
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

      if (widget.dataEdit != null && widget.dataEdit!.id != idFile) {
        await GensetModel.hapusFile(widget.dataEdit!.id);
      }

      await GensetModel.simpanKeFile(dataBaru);
      
      if (!mounted) return;
      setState(() => _isSaving = false);

      final pdfBytes = await PdfGenerator.buatPdf(dataBaru);
      if (!mounted) return;
      _tampilkanDialogBerhasil(pdfBytes, dataBaru.id);

    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _tampilkanDialogBerhasil(Uint8List pdfBytes, String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Berhasil Disimpan'),
        content: const Text('Data berhasil disimpan. Bagikan file PDF sekarang?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.dataEdit != null) Navigator.pop(context);
            },
            child: const Text('Tidak'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final tempDir = await getTemporaryDirectory();
              final tempFile = File('${tempDir.path}/$fileName.pdf');
              await tempFile.writeAsBytes(pdfBytes);
              
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(tempFile.path)],
                  text: 'File Pengujian Genset',
                ),
              );
              
              if (widget.dataEdit != null && mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.share),
            label: const Text('Ya, Bagikan'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BAGIAN 4: TAMPILAN UI (BUILD)
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
                  label: 'Tegangan Battery', // Typo sudah diperbaiki
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
                'Tegangan Output F/F', 'Tegangan Output F/N', 'Frekuensi', 'Cos Phi', 
                'Rpm Motor', 'Hour meter ON', 'Hour meter OFF', 'Temperatur Mesin', 
                'Temperatur Air Cooler', 'Temperatur Oli'
              ].map((key) => CustomNumberField(
                label: key,
                initialValue: _angkaValues[key],
                onChanged: (val) => _angkaValues[key] = val,
              )).toList(),
            ),
          ),

          // --- SECTION PELAKSANA & CATATAN ---
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PELAKSANA & CATATAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                for (int i = 0; i < 4; i++)
                  _buildTextField('Pelaksana ${i + 1}', 'Nama Pelaksana ${i + 1}', _pelaksanaControllers[i]),
                _buildTextField('Koordinator Pelaksana Fungsi', 'Nama Koordinator', _koordinatorController),
                const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _catatanController, maxLines: 4,
                  decoration: InputDecoration(hintText: 'Tambahkan catatan...', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ],
            ),
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

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}