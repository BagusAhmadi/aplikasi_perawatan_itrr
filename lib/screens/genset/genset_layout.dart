import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'genset_model.dart';
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
// BAGIAN 3: HALAMAN RIWAYAT (Edit, Hapus, Cetak PDF)
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await GensetModel.bacaSemua();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  // --- FUNGSI CETAK PDF SAJA (TANPA SHARE) ---
  Future<void> _buatDanSimpanPdf(GensetModel item) async {
    setState(() => _isProcessingPdf = true);
    try {
      final Uint8List pdfBytes = await PdfGenerator.buatPdf(item);
      
      // Menggunakan API FilePicker versi baru (bebas peringatan deprecated)
      final Uri? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Simpan PDF ke...',
        fileName: '${item.id}.pdf',
        bytes: pdfBytes,
        mimeType: 'application/pdf',
      );

      if (!mounted) return;
      setState(() => _isProcessingPdf = false);

      if (outputFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF berhasil disimpan: $outputFile')),
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
      await GensetModel.hapusFile(item.id);
      _loadData(); 
    }
  }

  // --- FUNGSI EDIT DATA ---
  void _editData(GensetModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GensetFormScreen(dataEdit: item)),
    ).then((_) => _loadData()); 
  }

  // ==========================================
  // BAGIAN 4: TAMPILAN DAFTAR RIWAYAT
  // ==========================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) {
      return const Center(child: Text('Belum ada riwayat pengujian.', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final item = _data[index];
          final tglFormatted = DateFormat('dd/MM/yyyy').format(item.tanggal);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.gedung} - $tglFormatted', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Icon(Icons.picture_as_pdf, color: Colors.red),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Pelaksana: ${item.pelaksana.isNotEmpty ? item.pelaksana.join(", ") : "-"}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Tombol Hapus
                      TextButton.icon(
                        onPressed: _isProcessingPdf ? null : () => _hapusData(item),
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      ),
                      // Tombol Edit
                      TextButton.icon(
                        onPressed: _isProcessingPdf ? null : () => _editData(item),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                      // Tombol Cetak PDF
                      ElevatedButton.icon(
                        onPressed: _isProcessingPdf ? null : () => _buatDanSimpanPdf(item),
                        icon: _isProcessingPdf 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.print, size: 18),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F51B5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}