import 'package:flutter/material.dart';

// ==========================================
// WIDGET: SECTION PELAKSANA & CATATAN
// ==========================================
class GensetPelaksanaSection extends StatelessWidget {
  final List<TextEditingController> pelaksanaControllers;
  final TextEditingController koordinatorController;
  final TextEditingController catatanController;

  const GensetPelaksanaSection({
    super.key,
    required this.pelaksanaControllers,
    required this.koordinatorController,
    required this.catatanController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PELAKSANA & CATATAN',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Loop untuk 4 Pelaksana
          for (int i = 0; i < 4; i++)
            _buildTextField(
              'Pelaksana ${i + 1}',
              'Nama Pelaksana ${i + 1}',
              pelaksanaControllers[i],
            ),
            
          // Koordinator
          _buildTextField(
            'Koordinator Pelaksana Fungsi',
            'Nama Koordinator',
            koordinatorController,
          ),
          
          // Catatan
          const Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 8),
          TextField(
            controller: catatanController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan...',
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk TextField
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