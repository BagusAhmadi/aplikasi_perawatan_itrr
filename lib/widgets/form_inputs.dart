import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==========================================
// BAGIAN 1: WIDGET INPUT ANGKA & MINUS
// ==========================================
class CustomNumberField extends StatelessWidget {
  final String label;
  final TextEditingController? controller; // Menggunakan controller agar teks bisa diupdate dari luar
  final ValueChanged<String>? onChanged;
  final Widget? bottomWidget;

  const CustomNumberField({
    super.key, 
    required this.label,
    this.controller,
    this.onChanged,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          // Jika onChanged null, input akan otomatis terkunci (read-only)
          onChanged: onChanged, 
          enabled: onChanged != null, 
          keyboardType: TextInputType.number,
          inputFormatters: [
            // Hanya menerima angka, koma, dan minus
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,-]')),
          ],
          decoration: InputDecoration(
            hintText: 'Masukkan angka & jika nilainya tidak diketahui cukup diisi "-" saja',
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            // Border saat input dikunci (disabled)
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black26),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 2),
            ),
          ),
        ),
        // Menampilkan widget tambahan (seperti checkbox) di bawah input
        if (bottomWidget != null) 
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: bottomWidget,
          ),
        const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}

// ==========================================
// BAGIAN 2: WIDGET RADIO BAIK/RUSAK
// ==========================================
class CustomRadioRow extends StatelessWidget {
  final String label;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const CustomRadioRow({
    super.key,
    required this.label,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 4),
        Row(
          children: [
            Radio<String>(
              value: 'baik',
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF3F51B5),
            ),
            const Text('Baik', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 16),
            Radio<String>(
              value: 'rusak',
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF3F51B5),
            ),
            const Text('Rusak', style: TextStyle(fontSize: 14)),
          ],
        ),
        const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}