import 'package:flutter/material.dart';
import 'genset_form_screen.dart';
import 'genset_riwayat_screen.dart'; // Import file baru
import '../home_screen.dart';

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
                  : const GensetRiwayatScreen(), // Panggil file baru di sini
            ),
          ),
        ],
      ),
    );
  }

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