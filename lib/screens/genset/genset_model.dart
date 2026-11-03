import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GensetModel {
  final String id;
  final DateTime tanggal;
  final String gedung;
  final Map<String, String> radioSebelum;
  final Map<String, String> angkaSaat;
  final List<String> pelaksana;
  final String catatan;

  GensetModel({
    required this.id,
    required this.tanggal,
    required this.gedung,
    required this.radioSebelum,
    required this.angkaSaat,
    required this.pelaksana,
    required this.catatan,
  });

  // ==========================================
  // BAGIAN 1: KONVERSI JSON
  // ==========================================
  Map<String, dynamic> toJson() => {
    'id': id,
    'tanggal': tanggal.toIso8601String(),
    'gedung': gedung,
    'radioSebelum': radioSebelum,
    'angkaSaat': angkaSaat,
    'pelaksana': pelaksana,
    'catatan': catatan,
  };

  factory GensetModel.fromJson(Map<String, dynamic> json) => GensetModel(
    id: json['id'],
    tanggal: DateTime.parse(json['tanggal']),
    gedung: json['gedung'],
    radioSebelum: Map<String, String>.from(json['radioSebelum']),
    angkaSaat: Map<String, String>.from(json['angkaSaat']),
    pelaksana: List<String>.from(json['pelaksana']),
    catatan: json['catatan'],
  );

  // ==========================================
  // BAGIAN 2: SIMPAN, BACA, HAPUS FILE
  // ==========================================
  static Future<File> simpanKeFile(GensetModel data) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${data.id}.json');
    await file.writeAsString(jsonEncode(data.toJson()));
    return file;
  }

  static Future<List<GensetModel>> bacaSemua() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    final List<GensetModel> result = [];

    if (!dir.existsSync()) return result;

    final files = dir.listSync().where((f) => f.path.endsWith('.json')).toList();
    for (var file in files) {
      try {
        final content = await File(file.path).readAsString();
        result.add(GensetModel.fromJson(jsonDecode(content)));
      } catch (e) {
        // Abaikan jika ada file korup
      }
    }
    result.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return result;
  }

  static Future<void> hapusFile(String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }
}