import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'genset_model.dart';

class GensetDatabase {
  static Database? _db;

  // ==========================================
  // BAGIAN 1: INISIALISASI DATABASE
  // ==========================================
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'genset.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Buat tabel utama
        await db.execute('''
          CREATE TABLE genset_pengujian (
            id TEXT PRIMARY KEY,
            tanggal TEXT,
            gedung TEXT,
            radio_sebelum TEXT,
            angka_saat TEXT,
            pelaksana TEXT,
            catatan TEXT
          )
        ''');
      },
    );
  }

  // ==========================================
  // BAGIAN 2: SIMPAN DATA (INSERT / UPDATE)
  // ==========================================
  static Future<void> simpan(GensetModel data) async {
    final db = await database;
    await db.insert(
      'genset_pengujian',
      {
        'id': data.id,
        'tanggal': data.tanggal.toIso8601String(),
        'gedung': data.gedung,
        'radio_sebelum': data.radioSebelum.toString(), // Simpan Map sebagai String
        'angka_saat': data.angkaSaat.toString(),       // Simpan Map sebagai String
        'pelaksana': data.pelaksana.join('|'),         // Gabungkan List dengan pemisah
        'catatan': data.catatan,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Timpa jika ID sama
    );
  }

  // ==========================================
  // BAGIAN 3: BACA SEMUA DATA
  // ==========================================
  static Future<List<GensetModel>> bacaSemua() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'genset_pengujian',
      orderBy: 'tanggal DESC',
    );

    return List.generate(maps.length, (i) {
      return GensetModel(
        id: maps[i]['id'],
        tanggal: DateTime.parse(maps[i]['tanggal']),
        gedung: maps[i]['gedung'],
        // Mengubah kembali String menjadi Map
        radioSebelum: _parseMap(maps[i]['radio_sebelum']),
        angkaSaat: _parseMap(maps[i]['angka_saat']),
        // Mengubah kembali String menjadi List
        pelaksana: maps[i]['pelaksana'].toString().split('|').where((s) => s.isNotEmpty).toList(),
        catatan: maps[i]['catatan'],
      );
    });
  }

  // ==========================================
  // BAGIAN 4: HAPUS DATA
  // ==========================================
  static Future<void> hapus(String id) async {
    final db = await database;
    await db.delete(
      'genset_pengujian',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // BAGIAN 5: CEK DUPLIKASI (Apakah ID sudah ada?)
  // ==========================================
  static Future<bool> cekIdExists(String id) async {
    final db = await database;
    final result = await db.query(
      'genset_pengujian',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }

  // ==========================================
  // BAGIAN 6: AMBIL HOUR METER OFF TERAKHIR
  // ==========================================
  static Future<String?> getHourMeterOffTerakhir() async {
    final db = await database;
    // Ambil data paling baru (DESC)
    final result = await db.query(
      'genset_pengujian',
      orderBy: 'tanggal DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final angkaMap = _parseMap(result.first['angka_saat']);
      final hourOff = angkaMap['Hour meter OFF'];
      if (hourOff != null && hourOff.trim().isNotEmpty && hourOff != '-') {
        return hourOff;
      }
    }
    return null;
  }

  // Helper untuk mengubah String kembali ke Map
  static Map<String, String> _parseMap(dynamic value) {
    if (value == null) return {};
    final str = value.toString();
    // Menghapus kurung kurawal { } agar bisa dipecah
    final cleanStr = str.substring(1, str.length - 1);
    if (cleanStr.isEmpty) return {};

    final Map<String, String> result = {};
    // Split berdasarkan koma, lalu split berdasarkan titik dua (:)
    final pairs = cleanStr.split(', ');
    for (var pair in pairs) {
      final parts = pair.split(': ');
      if (parts.length == 2) {
        result[parts[0]] = parts[1];
      }
    }
    return result;
  }
}