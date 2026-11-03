import 'package:flutter/material.dart';
import 'genset/genset_layout.dart';
import '../widgets/accordion_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _expandedMenu; // State menu yang terbuka

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Perawatan ITRR'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ==========================================
            // BAGIAN 1: MENU HARIAN
            // ==========================================
            AccordionSection(
              title: 'Harian',
              isExpanded: _expandedMenu == 'harian',
              onToggle: () => setState(() => _expandedMenu = _expandedMenu == 'harian' ? null : 'harian'),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada data untuk saat ini.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ),

            // ==========================================
            // BAGIAN 2: MENU MINGGUAN (Berisi Genset)
            // ==========================================
            AccordionSection(
              title: 'Mingguan',
              isExpanded: _expandedMenu == 'mingguan',
              onToggle: () => setState(() => _expandedMenu = _expandedMenu == 'mingguan' ? null : 'mingguan'),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Genset Tanpa Beban', style: TextStyle(fontSize: 15)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GensetLayout()),
                  );
                },
              ),
            ),

            // ==========================================
            // BAGIAN 3: MENU BULANAN
            // ==========================================
            AccordionSection(
              title: 'Bulanan',
              isExpanded: _expandedMenu == 'bulanan',
              onToggle: () => setState(() => _expandedMenu = _expandedMenu == 'bulanan' ? null : 'bulanan'),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada data untuk saat ini.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ),

            // ==========================================
            // BAGIAN 4: MENU 6 BULANAN
            // ==========================================
            AccordionSection(
              title: '6 Bulanan',
              isExpanded: _expandedMenu == '6bulanan',
              onToggle: () => setState(() => _expandedMenu = _expandedMenu == '6bulanan' ? null : '6bulanan'),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada data untuk saat ini.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ),

            // ==========================================
            // BAGIAN 5: MENU TAHUNAN
            // ==========================================
            AccordionSection(
              title: 'Tahunan',
              isExpanded: _expandedMenu == 'tahunan',
              onToggle: () => setState(() => _expandedMenu = _expandedMenu == 'tahunan' ? null : 'tahunan'),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada data untuk saat ini.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}