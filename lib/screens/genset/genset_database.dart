import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'genset_model.dart';

class GensetDatabase {
  static Database? _db;

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

  static Future<void> simpan(GensetModel data) async {
    final db = await database;
    await db.insert(
      'genset_pengujian',
      {
        'id': data.id,
        'tanggal': data.tanggal.toIso8601String(),
        'gedung': data.gedung,
        'radio_sebelum': data.radioSebelum.toString(),
        'angka_saat': data.angkaSaat.toString(),
        'pelaksana': data.pelaksana.join('|'),
        'catatan': data.catatan,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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
        radioSebelum: _parseMap(maps[i]['radio_sebelum']),
        angkaSaat: _parseMap(maps[i]['angka_saat']),
        pelaksana: maps[i]['pelaksana'].toString().split('|').where((s) => s.isNotEmpty).toList(),
        catatan: maps[i]['catatan'],
      );
    });
  }

  static Future<void> hapus(String id) async {
    final db = await database;
    await db.delete('genset_pengujian', where: 'id = ?', whereArgs: [id]);
  }

  static Future<bool> cekIdExists(String id) async {
    final db = await database;
    final result = await db.query('genset_pengujian', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }

  static Future<String?> getHourMeterOffTerakhir() async {
    final db = await database;
    final result = await db.query('genset_pengujian', orderBy: 'tanggal DESC', limit: 1);
    if (result.isNotEmpty) {
      final angkaMap = _parseMap(result.first['angka_saat']);
      final hourOff = angkaMap['Hour meter OFF'];
      if (hourOff != null && hourOff.trim().isNotEmpty && hourOff != '-') {
        return hourOff;
      }
    }
    return null;
  }

  static Map<String, String> _parseMap(dynamic value) {
    if (value == null) return {};
    final str = value.toString();
    final cleanStr = str.substring(1, str.length - 1);
    if (cleanStr.isEmpty) return {};
    final Map<String, String> result = {};
    final pairs = cleanStr.split(', ');
    for (var pair in pairs) {
      final parts = pair.split(': ');
      if (parts.length == 2) {
        result[parts[0]] = parts[1];
      }
    }
    return result;
  }

  // ==========================================
  // BAGIAN BARU: EKSPOR DATABASE (SQL)
  // ==========================================
  static Future<File?> eksporDatabase({
    DateTime? filterTanggal,
    int? filterBulan,
    int? filterTahun,
    String? filterGedung,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Bangun query dinamis berdasarkan filter
    List<String> conditions = [];
    if (filterTanggal != null) {
      final start = DateTime(filterTanggal.year, filterTanggal.month, filterTanggal.day);
      final end = start.add(const Duration(days: 1));
      conditions.add('tanggal >= ? AND tanggal < ?');
      whereArgs.add(start.toIso8601String());
      whereArgs.add(end.toIso8601String());
    }
    if (filterBulan != null && filterTahun != null) {
      final start = DateTime(filterTahun, filterBulan, 1);
      final end = DateTime(filterTahun, filterBulan + 1, 1);
      conditions.add('tanggal >= ? AND tanggal < ?');
      whereArgs.add(start.toIso8601String());
      whereArgs.add(end.toIso8601String());
    }
    if (filterGedung != null) {
      conditions.add('gedung = ?');
      whereArgs.add(filterGedung);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    // Ambil data sesuai filter
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM genset_pengujian $whereClause',
      whereArgs,
    );

    if (maps.isEmpty) return null;

    // Buat database baru sementara
    final tempDir = await getTemporaryDirectory();
    final tempPath = join(tempDir.path, 'ekspor_genset.db');
    
    // Hapus file lama jika ada
    final tempFile = File(tempPath);
    if (await tempFile.exists()) await tempFile.delete();

    final tempDb = await openDatabase(tempPath, version: 1, onCreate: (db, version) async {
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
    });

    // Salin data ke database baru
    for (var map in maps) {
      await tempDb.insert('genset_pengujian', map);
    }
    await tempDb.close();

    return tempFile;
  }
}