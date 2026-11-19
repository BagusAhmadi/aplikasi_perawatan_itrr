import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/form_inputs.dart';
import 'genset_model.dart';
import 'genset_database.dart';
import 'pdf_generator.dart';
import 'genset_pelaksana_section.dart';
import 'pdf_preview_screen.dart';

class GensetFormScreen extends StatefulWidget {
  final String gedungSSK; // Menerima parameter gedung dari halaman depan
  const GensetFormScreen({super.key, required this.gedungSSK});

  @override
  State<GensetFormScreen> createState() => _GensetFormScreenState();
}

class _GensetFormScreenState extends State<GensetFormScreen> {
  // ==========================================
  // BAGIAN 1: STATE / VARIABEL DATA FORM
  // ==========================================
  DateTime _tanggalTerpilih = DateTime.now();
  late String _pilihanGedung; // Menggunakan 'late' karena diisi di initState

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

  final Map<String, TextEditingController> _angkaControllers = {};

  final List<TextEditingController> _pelaksanaControllers = List.generate(4, (index) => TextEditingController());
  final TextEditingController _koordinatorController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  bool _isSaving = false;
  
  bool _isHourMeterLocked = false;
  String? _hourMeterOffSebelumnya;
  bool _isLoadingHourMeter = false;

  bool _isFormValid = false; 

  @override
  void initState() {
    super.initState();
    
    // Inisialisasi gedung berdasarkan parameter dari halaman depan
    _pilihanGedung = widget.gedungSSK.replaceAll(' ', '_');

    for (var key in _angkaValues.keys) {
      _angkaControllers[key] = TextEditingController(text: _angkaValues[key]);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _cekHourMeterSebelumnya());
  }

  @override
  void dispose() {
    for (var c in _pelaksanaControllers) { c.dispose(); }
    for (var c in _angkaControllers.values) { c.dispose(); }
    _koordinatorController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  // ==========================================
  // BAGIAN 2: FUNGSI RESET FORM
  // ==========================================
  void _resetForm() {
    setState(() {
      _tanggalTerpilih = DateTime.now();
      // Gedung tidak di-reset, tetap menggunakan gedungSSK
      
      _radioValues.updateAll((key, value) => 'baik');
      
      for (var key in _angkaValues.keys) {
        _angkaValues[key] = '';
        _angkaControllers[key]?.clear();
      }

      for (var c in _pelaksanaControllers) { c.clear(); }
      _koordinatorController.clear();
      _catatanController.clear();

      _isFormValid = false; 
    });
    
    _cekHourMeterSebelumnya(); 
  }

  // ==========================================
  // BAGIAN 3: VALIDASI FORM
  // ==========================================
  void _cekValidasi() {
    bool allAngkaValid = _angkaValues.values.every((val) => val.trim().isNotEmpty);
    bool adaPelaksana = _pelaksanaControllers.any((c) => c.text.trim().isNotEmpty);
    bool adaKoordinator = _koordinatorController.text.trim().isNotEmpty;

    bool isValid = allAngkaValid && adaPelaksana && adaKoordinator;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  // ==========================================
  // BAGIAN 4: FUNGSI CEK HOUR METER SEBELUMNYA
  // ==========================================
  Future<void> _cekHourMeterSebelumnya() async {
    setState(() {
      _isLoadingHourMeter = true;
      _isHourMeterLocked = false; 
      _hourMeterOffSebelumnya = null;
      _angkaValues['Hour meter ON'] = '';
      _angkaControllers['Hour meter ON']?.clear();
    });

    final val = await GensetDatabase.getHourMeterOffSebelumnya(
      gedung: _pilihanGedung.replaceAll('_', ' '),
      tanggal: _tanggalTerpilih,
    );

    if (!mounted) return;
    setState(() {
      _hourMeterOffSebelumnya = val;
      _isLoadingHourMeter = false;
    });
    _cekValidasi();
  }

  // ==========================================
  // BAGIAN 5: LOGIKA SIMPAN DATA & BUKA PREVIEW
  // ==========================================
  Future<void> _simpanData() async {
    final idFile = 'Genset_${_pilihanGedung}_${DateFormat('yyyy-MM-dd').format(_tanggalTerpilih)}';

    final isExist = await GensetDatabase.cekIdExists(idFile);
    if (isExist) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Gagal Menyimpan'),
          content: Text('Data untuk ${_pilihanGedung.replaceAll('_', ' ')} pada tanggal ${DateFormat('dd/MM/yyyy').format(_tanggalTerpilih)} sudah ada.'),
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
        tanggal: _tanggalTerpilih,
        gedung: _pilihanGedung.replaceAll('_', ' '),
        radioSebelum: _radioValues,
        angkaSaat: _angkaValues,
        pelaksana: daftarPelaksana,
        catatan: _catatanController.text.trim(),
      );

      await GensetDatabase.simpan(dataBaru);
      
      if (!mounted) return;
      setState(() => _isSaving = false);

      final pdfBytes = await PdfGenerator.buatPdf(dataBaru);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfBytes: pdfBytes,
            fileName: 'Laporan_${dataBaru.id}.pdf',
          ),
        ),
      );

      if (mounted) {
        _resetForm();
      }

    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // ==========================================
  // BAGIAN 6: TAMPILAN UI (BUILD)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    // Format nama gedung untuk tampilan (Gedung 11 / Gedung 13)
    String namaGedungTampil = widget.gedungSSK == 'gedung 11' ? 'Gedung 11' : 'Gedung 13';

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
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context, 
                        initialDate: _tanggalTerpilih, 
                        firstDate: DateTime(2020), 
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _tanggalTerpilih = picked);
                        _cekHourMeterSebelumnya();
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      DateFormat('EEEE, dd/MM/yyyy', 'id_ID').format(_tanggalTerpilih),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      foregroundColor: const Color(0xFF3F51B5),
                      side: const BorderSide(color: Color(0xFF3F51B5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- SECTION GEDUNG (TERKUNCI) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GEDUNG PENGUJIAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.blueGrey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      namaGedungTampil,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- SECTION SEBELUM RUNNING ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PEMERIKSAAN SEBELUM RUNNING TEST GENSET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3F51B5))),
                const Divider(),
                const SizedBox(height: 8),
                
                ..._radioValues.keys.map((key) => CustomRadioRow(
                  label: key,
                  groupValue: _radioValues[key]!,
                  onChanged: (val) => setState(() => _radioValues[key] = val!),
                )),
                CustomNumberField(
                  label: 'Battery Charger',
                  controller: _angkaControllers['Battery Charger'],
                  onChanged: (val) {
                    _angkaValues['Battery Charger'] = val;
                    _cekValidasi();
                  },
                ),
                CustomNumberField(
                  label: 'Tegangan Battery',
                  controller: _angkaControllers['Tegangan Battery'],
                  onChanged: (val) {
                    _angkaValues['Tegangan Battery'] = val;
                    _cekValidasi();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- SECTION SAAT RUNNING ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PEMERIKSAAN SAAT RUNNING TEST GENSET', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3F51B5))),
                const Divider(),
                const SizedBox(height: 8),

                ...['Tegangan Output F/F', 'Tegangan Output F/N', 'Frekuensi', 'Cos Phi', 
                'Rpm Motor'].map((key) => CustomNumberField(
                  label: key,
                  controller: _angkaControllers[key],
                  onChanged: (val) {
                    _angkaValues[key] = val;
                    _cekValidasi();
                  },
                )),
                
                CustomNumberField(
                  label: 'Hour meter ON',
                  controller: _angkaControllers['Hour meter ON'],
                  onChanged: _isHourMeterLocked ? null : (val) {
                    _angkaValues['Hour meter ON'] = val;
                    _cekValidasi();
                  },
                  bottomWidget: _isLoadingHourMeter
                      ? const Padding(padding: EdgeInsets.all(8.0), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                      : Row(
                          children: [
                            Checkbox(
                              value: _isHourMeterLocked,
                              onChanged: _hourMeterOffSebelumnya == null
                                  ? null
                                  : (bool? value) {
                                      setState(() {
                                        _isHourMeterLocked = value ?? false;
                                        if (_isHourMeterLocked) {
                                          _angkaValues['Hour meter ON'] = _hourMeterOffSebelumnya!;
                                          _angkaControllers['Hour meter ON']?.text = _hourMeterOffSebelumnya!;
                                        } else {
                                          _angkaValues['Hour meter ON'] = '';
                                          _angkaControllers['Hour meter ON']?.clear();
                                        }
                                      });
                                      _cekValidasi();
                                    },
                            ),
                            Expanded(
                              child: Text(
                                _hourMeterOffSebelumnya == null ? 'Tidak ada data OFF sebelumnya' : 'Gunakan Hour meter OFF sebelumnya (${_hourMeterOffSebelumnya})',
                                style: TextStyle(fontSize: 12, color: _hourMeterOffSebelumnya == null ? Colors.grey : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                ),

                CustomNumberField(
                  label: 'Hour meter OFF',
                  controller: _angkaControllers['Hour meter OFF'],
                  onChanged: (val) {
                    _angkaValues['Hour meter OFF'] = val;
                    _cekValidasi();
                  },
                ),
                
                ...['Temperatur Mesin', 'Temperatur Air Cooler', 'Temperatur Oli']
                .map((key) => CustomNumberField(
                  label: key, 
                  controller: _angkaControllers[key],
                  onChanged: (val) {
                    _angkaValues[key] = val;
                    _cekValidasi();
                  },
                )).toList(),
              ],
            ),
          ),

          // --- SECTION PELAKSANA & CATATAN ---
          GensetPelaksanaSection(
            pelaksanaControllers: _pelaksanaControllers,
            koordinatorController: _koordinatorController,
            catatanController: _catatanController,
            onTextChanged: _cekValidasi,
          ),

          // --- TOMBOL SIMPAN ---
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: (_isFormValid && !_isSaving) ? _simpanData : null,
            icon: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Menyimpan...' : 'Simpan ke Riwayat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              disabledBackgroundColor: Colors.grey[400],
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