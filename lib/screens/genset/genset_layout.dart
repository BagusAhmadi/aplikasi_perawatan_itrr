import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'genset_model.dart';
import 'genset_database.dart';
import 'genset_form_screen.dart';
import 'pdf_generator.dart';
import '../home_screen.dart';

// ==========================================
// BAGIAN 1: LAYOUT UTAMA (SIDEBAR & NAVIGASI)
// ==========================================
class GensetLayout extends StatefulWidget {
  const GensetLayout({super.key});

  @override
  State<GensetLayout> createState() => _GensetLayoutState();
}

class _GensetLayoutState extends State<GensetLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<String> _titles = [
    'Form Pengujian Genset',
    'Riwayat Pengujian Genset',
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex], style: const TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: isMobile ? Drawer(child: _buildSidebarContent()) : null,
      body: Row(
        children: [
          // Sidebar untuk Desktop
          if (!isMobile)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSidebarCollapsed ? 70 : 250,
              color: Colors.white,
              child: _buildSidebarContent(isDesktop: true),
            ),
          if (!isMobile) const VerticalDivider(width: 1, thickness: 1),
          
          // Area Konten Utama
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _selectedIndex == 0
                  ? const GensetFormScreen()
                  : const _RiwayatGensetScreen(), 
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BAGIAN 2: ISI SIDEBAR
  // ==========================================
  Widget _buildSidebarContent({bool isDesktop = false}) {
    return Column(
      children: [
        Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 0 : 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [
              if (!_isSidebarCollapsed)
                const Text('Menu Genset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
              if (isDesktop)
                IconButton(
                  icon: Icon(_isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left, color: Colors.grey[700]),
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildMenuItem(
                icon: Icons.arrow_back, title: 'Kembali ke Menu Awal', isActive: false, isDesktop: isDesktop,
                onTap: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                },
              ),
              const Divider(),
              _buildMenuItem(
                icon: Icons.assignment, title: 'Pengisian', isActive: _selectedIndex == 0, isDesktop: isDesktop,
                onTap: () {
                  setState(() => _selectedIndex = 0);
                  if (!isDesktop) Navigator.pop(context);
                },
              ),
              _buildMenuItem(
                icon: Icons.history, title: 'Riwayat', isActive: _selectedIndex == 1, isDesktop: isDesktop,
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  if (!isDesktop) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required bool isActive, required VoidCallback onTap, required bool isDesktop}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _isSidebarCollapsed ? 0 : 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8EAF6) : Colors.transparent,
          border: Border(left: BorderSide(color: isActive ? const Color(0xFF3F51B5) : Colors.transparent, width: 4)),
        ),
        child: Row(
          mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF3F51B5) : Colors.grey[600]),
            if (!_isSidebarCollapsed) ...[
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? const Color(0xFF3F51B5) : Colors.grey[800]))),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// BAGIAN 3: HALAMAN RIWAYAT (KALENDER & EKSPOR)
// ==========================================
class _RiwayatGensetScreen extends StatefulWidget {
  const _RiwayatGensetScreen();

  @override
  State<_RiwayatGensetScreen> createState() => _RiwayatGensetScreenState();
}

class _RiwayatGensetScreenState extends State<_RiwayatGensetScreen> {
  List<GensetModel> _data = [];
  bool _isLoading = true;
  bool _isProcessingPdf = false;

  // State untuk Kalender
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
      _data = data;
      _isLoading = false;
    });
  }

  // --- FUNGSI CETAK PDF ---
  Future<void> _buatDanSimpanPdf(GensetModel item) async {
    setState(() => _isProcessingPdf = true);
    try {
      final Uint8List pdfBytes = await PdfGenerator.buatPdf(item);
      
      final Uri? outputUri = await FilePicker.saveFile(
        dialogTitle: 'Simpan PDF ke...',
        fileName: '${item.id}.pdf',
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      if (!mounted) return;
      setState(() => _isProcessingPdf = false);

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
      if (!mounted) return;
      setState(() => _isProcessingPdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencetak PDF: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- FUNGSI HAPUS DATA ---
  Future<void> _hapusData(GensetModel item) async {
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
      _loadData(); 
    }
  }

  // --- FUNGSI EKSPOR DATABASE ---
  Future<void> _eksporDatabaseSaja() async {
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
                const Text('Pilih Data yang Diekspor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.all_inbox),
                  title: const Text('Semua Data'),
                  onTap: () { Navigator.pop(ctx); _prosesEkspor(); },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Per Bulan'),
                  onTap: () { Navigator.pop(ctx); _pilihBulanEkspor(); },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Per Hari'),
                  onTap: () { Navigator.pop(ctx); _pilihHariEkspor(); },
                ),
                ListTile(
                  leading: const Icon(Icons.apartment),
                  title: const Text('Per Gedung'),
                  onTap: () { Navigator.pop(ctx); _pilihGedungEkspor(); },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pilihBulanEkspor() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Pilih Bulan (Tanggal tidak penting)',
    );
    if (picked != null) {
      _prosesEkspor(bulan: picked.month, tahun: picked.year);
    }
  }

  Future<void> _pilihHariEkspor() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _prosesEkspor(tanggal: picked);
    }
  }

  Future<void> _pilihGedungEkspor() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Gedung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('Gedung 11'), onTap: () { Navigator.pop(ctx); _prosesEkspor(gedung: 'gedung 11'); }),
            ListTile(title: const Text('Gedung 13'), onTap: () { Navigator.pop(ctx); _prosesEkspor(gedung: 'gedung 13'); }),
          ],
        ),
      ),
    );
  }

  Future<void> _prosesEkspor({DateTime? tanggal, int? bulan, int? tahun, String? gedung}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menyiapkan file database...')),
    );

    final file = await GensetDatabase.eksporDatabase(
      filterTanggal: tanggal,
      filterBulan: bulan,
      filterTahun: tahun,
      filterGedung: gedung,
    );

    if (file != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Backup Database Genset',
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data yang sesuai filter untuk diekspor.'), backgroundColor: Colors.red),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tombol Ekspor Database
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _eksporDatabaseSaja,
              icon: const Icon(Icons.save_alt),              label: const Text('Ekspor Database'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Container Kalender
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].map((day) => 
                    SizedBox(width: 32, child: Text(day, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)))
                  ).toList(),
                ),
                const Divider(),
                _buildCalendarGrid(),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Daftar Perbaikan
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

  // Grid Kalender
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    int firstWeekday = firstDayOfMonth.weekday; 
    int totalDays = lastDayOfMonth.day;
    
    List<Widget> dayWidgets = [];

    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 36, height: 36));
    }

    for (int i = 1; i <= totalDays; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      final hasData = _hasDataOnDate(date);
      final isSelected = _selectedDate != null && 
                         _selectedDate!.day == i && 
                         _selectedDate!.month == _currentMonth.month &&
                         _selectedDate!.year == _currentMonth.year;

      dayWidgets.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.all(2),
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
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 2,
      runSpacing: 2,
      children: dayWidgets,
    );
  }

  // Kartu Riwayat
  Widget _buildRiwayatCard(GensetModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.gedung, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text('Pelaksana: ${item.pelaksana.isNotEmpty ? item.pelaksana.join(", ") : "-"}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
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
                  onPressed: _isProcessingPdf ? null : () => _buatDanSimpanPdf(item),
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