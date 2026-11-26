import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'genset/genset_model.dart';
import 'genset/genset_database.dart';
import 'genset/genset_riwayat_logic.dart';
import 'genset/pdf_generator.dart';
import 'genset/pdf_preview_screen.dart';
import 'cetak_blanko_screen.dart'; // Import untuk navigasi sidebar

class GlobalRiwayatScreen extends StatefulWidget {
  const GlobalRiwayatScreen({super.key});

  @override
  State<GlobalRiwayatScreen> createState() => _GlobalRiwayatScreenState();
}

class _GlobalRiwayatScreenState extends State<GlobalRiwayatScreen> {
  List<GensetModel> _allData = [];
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
    final data = await GensetDatabase.bacaSemua();
    setState(() {
      _allData = data;
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

  bool _hasDataOnDate(DateTime date) {
    return _allData.any((item) => 
      item.tanggal.year == date.year &&
      item.tanggal.month == date.month &&
      item.tanggal.day == date.day
    );
  }

  List<GensetModel> _getDataForSelectedDate() {
    if (_selectedDate == null) return [];
    return _allData.where((item) => 
      item.tanggal.year == _selectedDate!.year &&
      item.tanggal.month == _selectedDate!.month &&
      item.tanggal.day == _selectedDate!.day
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      // ==========================================
      // MENAMBAHKAN DRAWER / SIDEBAR
      // ==========================================
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF3F51B5)),
              child: Text(
                'Menu Utama',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Pengisian'),
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Riwayat Semua Perawatan'),
              selected: true,
              selectedTileColor: const Color(0xFFE8EAF6),
              selectedColor: const Color(0xFF3F51B5),
              onTap: () {
                Navigator.pop(context); // Tutup drawer jika sedang di halaman ini
              },
            ),
            // Garis pemisah (Divider) dihapus
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Cetak Tabel Kosong'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CetakBlankoScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Riwayat Semua Perawatan'),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        // ==========================================
        // MENGGANTI TOMBOL BACK JADI HAMBURGER
        // ==========================================
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu), 
            onPressed: () => Scaffold.of(context).openDrawer(), 
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  _eksporSemuaData();
                },
                icon: const Icon(Icons.save_alt),
                label: const Text('Ekspor Semua Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                  child: const Text('Tidak ada perawatan pada tanggal ini.', style: TextStyle(color: Colors.grey)),
                )
              else
                ..._getDataForSelectedDate().map((item) => _buildRiwayatCard(item)),
            ],
          ],
        ),
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

  Widget _buildRiwayatCard(GensetModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Future<void> _eksporSemuaData() async {
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
                const Text('Pilih Waktu Ekspor (Semua Gedung)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.all_inbox),
                  title: const Text('Semua Data'),
                  onTap: () { 
                    Navigator.pop(ctx); 
                    GensetRiwayatLogic.mulaiEksporDatabase(context, _loadData, filterGedung: 'semua');
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
                      // Bisa disesuaikan untuk filter bulan dengan 'semua'
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
}