import 'package:flutter/material.dart';
import 'genset/genset_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State untuk menyimpan nilai yang dipilih
  String? _selectedInstalasi;
  String? _selectedPeriode;
  String? _selectedSSK;
  String? _selectedJenis;

  @override
  Widget build(BuildContext context) {
    // Cek apakah semua form sudah terisi untuk mengaktifkan tombol
    bool isFormComplete = _selectedInstalasi != null &&
        _selectedPeriode != null &&
        _selectedSSK != null &&
        _selectedJenis != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ==========================================
              // HEADER BIRU
              // ==========================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF3F51B5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4D3F51B5),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ]
                ),
                child: const Text(
                  'Aplikasi Perawatan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // ==========================================
              // KONTEN FORM
              // ==========================================
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    // 1. Dropdown Instalasi
                    _buildLabel('Pilih Instalasi / Kawasan'),
                    _buildDropdown(
                      hint: '-- Pilih Instalasi --',
                      value: _selectedInstalasi,
                      items: ['ITRR'],
                      enabled: true,
                      onChanged: (val) {
                        setState(() {
                          _selectedInstalasi = val;
                          // Reset dropdown di bawahnya jika yang atas berubah
                          _selectedPeriode = null;
                          _selectedSSK = null;
                          _selectedJenis = null;
                        });
                      },
                    ),

                    // 2. Dropdown Periode
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

                    // 3. Dropdown SSK
                    _buildLabel('SSK'),
                    _buildDropdown(
                      hint: _selectedPeriode == null ? '-- Pilih Periode Dulu --' : '-- Pilih SSK --',
                      value: _selectedSSK,
                      items: _selectedPeriode != null ? ['Sistem Catudaya Listrik Emergency'] : [],
                      enabled: _selectedPeriode != null,
                      onChanged: (val) {
                        setState(() {
                          _selectedSSK = val;
                          _selectedJenis = null;
                        });
                      },
                    ),

                    // 4. Dropdown Jenis Pengujian
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

                    // ==========================================
                    // TOMBOL BUKA
                    // ==========================================
                    ElevatedButton(
                      onPressed: isFormComplete
                          ? () {
                              // Navigasi ke halaman Genset
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GensetLayout(),
                                ),
                              );
                            }
                          : null, // Tombol disabled jika form belum lengkap
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
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET HELPER UNTUK LABEL
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

  // ==========================================
  // WIDGET HELPER UNTUK DROPDOWN
  // ==========================================
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
          fillColor: enabled ? Colors.white : const Color(0xFFEEEEEE), // Abu-abu jika disabled
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
        // Jika enabled false, kita set onChanged ke null agar dropdown tidak bisa dibuka
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