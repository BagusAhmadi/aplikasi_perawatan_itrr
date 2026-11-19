import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'genset_model.dart';
import 'genset_riwayat_logic.dart';
import 'pdf_generator.dart';
import 'pdf_preview_screen.dart';

class GensetRiwayatScreen extends StatefulWidget {
  final String gedungSSK; // Menerima parameter gedung dari halaman depan
  const GensetRiwayatScreen({super.key, required this.gedungSSK});

  @override
  State<GensetRiwayatScreen> createState() => _GensetRiwayatScreenState();
}

class _GensetRiwayatScreenState extends State<GensetRiwayatScreen> {
  List<GensetModel> _allData = []; // Data asli dari database
  List<GensetModel> _data = [];    // Data yang sudah difilter berdasarkan gedung
  bool _isLoading = true;
  bool _isProcessingPdf = false;

  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
    _selectedDate = DateTime.now();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await GensetRiwayatLogic.loadData();
    setState(() {
      _allData = data;
      // Filter HANYA menampilkan data dari gedung yang dipilih di halaman depan
      _data = _allData.where((item) => 
        item.gedung.toLowerCase() == widget.gedungSSK.toLowerCase()
      ).toList();
      _isLoading = false;
    });
  }

  void _hapusData(GensetModel item) async {
    final berhasil = await GensetRiwayatLogic.konfirmasiHapus(context, item);
    if (berhasil) _loadData();
  }

  void _cetakPdf(GensetModel item) {
    GensetRiwayatLogic.buatDanSimpanPdf(context, item, (loading) {
      setState(() => _isProcessingPdf = loading);
    });
  }

  // ==========================================
  // FUNGSI BUKA PRATINJAU PDF (KLIK AREA ATAS)
  // ==========================================
  Future<void> _bukaPratinjauPdf(GensetModel item) async {
    try {
      final Uint8List pdfBytes = await PdfGenerator.buatPdf(item);
      if (!mounted) return;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfBytes: pdfBytes,
            fileName: 'Laporan_${item.id}.pdf',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- LOGIKA KALENDER ---
  bool _hasDataOnDate(DateTime date) {
    return _data.any((item) => 
      item.tanggal.year == date.year &&
      item.tanggal.month == date.month &&
      item.tanggal.day == date.day
    );
  }

  List<GensetModel> _getDataForSelectedDate() {
    if (_selectedDate == null) return [];
    return _data.where((item) => 
      item.tanggal.year == _selectedDate!.year &&
      item.tanggal.month == _selectedDate!.month &&
      item.tanggal.day == _selectedDate!.day
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Teks tombol ekspor menyesuaikan gedung
    String namaGedung = widget.gedungSSK == 'gedung 11' ? 'GD 11' : 'GD 13';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => GensetRiwayatLogic.mulaiEksporDatabase(
                context, 
                _loadData,
                filterGedung: widget.gedungSSK, // Kirim filter gedung ke logic
              ),
              icon: const Icon(Icons.save_alt),
              label: Text('Ekspor DB ($namaGedung)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // KOTAK KALENDER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'id_ID').format(_currentMonth),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].map((day) => 
                        SizedBox(
                          width: 44, 
                          child: Text(day, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))
                        )
                      ).toList(),
                    ),
                  ),
                ),
                
                const Divider(),
                _buildCalendarGrid(),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          if (_selectedDate != null) ...[
            Text(
              'Tanggal Terpilih: ${DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (_getDataForSelectedDate().isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Text('Tidak ada perbaikan pada tanggal ini.', style: TextStyle(color: Colors.grey)),
              )
            else
              ..._getDataForSelectedDate().map((item) => _buildRiwayatCard(item)),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    int firstWeekday = firstDayOfMonth.weekday; 
    int totalDays = lastDayOfMonth.day;
    
    List<Widget> dayWidgets = [];

    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 44, height: 44));
    }

    for (int i = 1; i <= totalDays; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      final hasData = _hasDataOnDate(date);
      final isSelected = _selectedDate != null && 
                         _selectedDate!.day == i && 
                         _selectedDate!.month == _currentMonth.month &&
                         _selectedDate!.year == _currentMonth.year;

      dayWidgets.add(
        Container(
          width: 44, 
          height: 44, 
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 36, 
              height: 36,
              decoration: BoxDecoration(
                color: isSelected 
                  ? const Color(0xFF3F51B5)
                  : hasData 
                    ? Colors.green 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3F51B5) : Colors.transparent,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$i',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected || hasData ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 308), 
        child: Wrap(
          alignment: WrapAlignment.start,
          children: dayWidgets,
        ),
      ),
    );
  }

  // ==========================================
  // KARTU RIWAYAT
  // ==========================================
  Widget _buildRiwayatCard(GensetModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- AREA ATAS: BISA DIKLIK UNTUK BUKA PDF ---
            InkWell(
              onTap: () => _bukaPratinjauPdf(item),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.gedung, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Pelaksana: ${item.pelaksana.isNotEmpty ? item.pelaksana.join(", ") : "-"}', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('(Ketuk untuk melihat PDF)', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blue)),
                        ],
                      ),
                    ),
                    const Icon(Icons.picture_as_pdf, color: Colors.red, size: 28),
                  ],
                ),
              ),
            ),
            
            const Divider(),

            // --- AREA BAWAH: TOMBOL HAPUS & PDF ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _isProcessingPdf ? null : () => _hapusData(item),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isProcessingPdf ? null : () => _cetakPdf(item),
                  icon: _isProcessingPdf 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.print, size: 18),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}