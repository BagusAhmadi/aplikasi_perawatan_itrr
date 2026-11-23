import 'package:flutter/material.dart';
import 'genset/genset_layout.dart';
import 'global_riwayat_screen.dart'; // Import halaman riwayat global
import 'cetak_blanko_screen.dart';   // Import halaman cetak blanko

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // 0 = Pengisian, 1 = Riwayat Global

  // State Form Dropdown
  String? _selectedInstalasi;
  String? _selectedPeriode;
  String? _selectedSSK;
  String? _selectedJenis;

  @override
  Widget build(BuildContext context) {
    bool isFormComplete = _selectedInstalasi != null &&
        _selectedPeriode != null &&
        _selectedSSK != null &&
        _selectedJenis != null;

    String gedungTerpilih = _selectedSSK == 'Sistem Catudaya Listrik Emergency GD 11' 
        ? 'gedung 11' 
        : 'gedung 13';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      // ==========================================
      // SIDEBAR (DRAWER)
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
              selected: _selectedIndex == 0,
              selectedTileColor: const Color(0xFFE8EAF6),
              selectedColor: const Color(0xFF3F51B5),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Riwayat Semua Perawatan'),
              selected: _selectedIndex == 1,
              selectedTileColor: const Color(0xFFE8EAF6),
              selectedColor: const Color(0xFF3F51B5),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Cetak Tabel Kosong'),
              onTap: () {
                Navigator.pop(context); // Tutup sidebar
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CetakBlankoScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      // ==========================================
      // APPBAR
      // ==========================================
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Aplikasi Perawatan' : 'Riwayat Semua'),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),
      // ==========================================
      // ISI HALAMAN
      // ==========================================
      body: _selectedIndex == 0 
          ? _buildFormPengisian(isFormComplete, gedungTerpilih)
          : const GlobalRiwayatScreen(),
    );
  }

  // ==========================================
  // UI FORM PENGISIAN (DROPDOWN BERTINGKAT)
  // ==========================================
  Widget _buildFormPengisian(bool isFormComplete, String gedungTerpilih) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLabel('Pilih Instalasi / Kawasan'),
                _buildDropdown(
                  hint: '-- Pilih Instalasi --',
                  value: _selectedInstalasi,
                  items: ['ITRR'],
                  enabled: true,
                  onChanged: (val) {
                    setState(() {
                      _selectedInstalasi = val;
                      _selectedPeriode = null;
                      _selectedSSK = null;
                      _selectedJenis = null;
                    });
                  },
                ),

                _buildLabel('Periode'),
                _buildDropdown(
                  hint: _selectedInstalasi == null ? '-- Pilih Instalasi Dulu --' : '-- Pilih Periode --',
                  value: _selectedPeriode,
                  items: _selectedInstalasi != null ? ['1 Mingguan'] : [],
                  enabled: _selectedInstalasi != null,
                  onChanged: (val) {
                    setState(() {
                      _selectedPeriode = val;
                      _selectedSSK = null;
                      _selectedJenis = null;
                    });
                  },
                ),

                _buildLabel('SSK'),
                _buildDropdown(
                  hint: _selectedPeriode == null ? '-- Pilih Periode Dulu --' : '-- Pilih SSK --',
                  value: _selectedSSK,
                  items: _selectedPeriode != null 
                      ? [
                          'Sistem Catudaya Listrik Emergency GD 11',
                          'Sistem Catudaya Listrik Emergency GD 13'
                        ] 
                      : [],
                  enabled: _selectedPeriode != null,
                  onChanged: (val) {
                    setState(() {
                      _selectedSSK = val;
                      _selectedJenis = null;
                    });
                  },
                ),

                _buildLabel('Jenis Pengujian / Perawatan'),
                _buildDropdown(
                  hint: _selectedSSK == null ? '-- Pilih SSK Dulu --' : '-- Pilih Jenis Pengujian --',
                  value: _selectedJenis,
                  items: _selectedSSK != null ? ['Uji running tanpa beban 15 menit'] : [],
                  enabled: _selectedSSK != null,
                  onChanged: (val) {
                    setState(() {
                      _selectedJenis = val;
                    });
                  },
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: isFormComplete
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GensetLayout(
                                gedungSSK: gedungTerpilih,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F51B5),
                    disabledBackgroundColor: const Color(0xFFB0BEC5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: isFormComplete ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Buka Form Pengujian',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER UNTUK LABEL & DROPDOWN
  // ==========================================
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required bool enabled,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        hint: Text(
          hint,
          style: TextStyle(
            fontSize: 14,
            color: enabled ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: enabled ? Colors.grey[800] : Colors.grey[400],
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFEEEEEE),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 2),
          ),
        ),
        onChanged: enabled ? onChanged : null,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          );
        }).toList(),
      ),
    );
  }
}