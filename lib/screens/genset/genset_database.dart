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
      version: 2, // <-- Naikkan versi database
      onCreate: (db, version) async {
        // TABEL BARU DENGAN KOLOM YANG JELAS
        await db.execute('''
          CREATE TABLE genset_pengujian (
            id TEXT PRIMARY KEY,
            tanggal TEXT,
            gedung TEXT,
            oli_mesin TEXT,
            pemanas_oli TEXT,
            air_radiator TEXT,
            van_belt TEXT,
            solar TEXT,
            air_accu TEXT,
            battery_charger TEXT,
            tegangan_battery TEXT,
            tegangan_ff TEXT,
            tegangan_fn TEXT,
            frekuensi TEXT,
            cos_phi TEXT,
            rpm_motor TEXT,
            hour_on TEXT,
            hour_off TEXT,
            temp_mesin TEXT,
            temp_cooler TEXT,
            temp_oli TEXT,
            pelaksana_1 TEXT,
            pelaksana_2 TEXT,
            pelaksana_3 TEXT,
            pelaksana_4 TEXT,
            koordinator TEXT,
            catatan TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Jika sebelumnya sudah ada tabel versi 1, hapus dan buat baru
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS genset_pengujian');
          await db.execute('''
            CREATE TABLE genset_pengujian (
              id TEXT PRIMARY KEY,
              tanggal TEXT,
              gedung TEXT,
              oli_mesin TEXT,
              pemanas_oli TEXT,
              air_radiator TEXT,
              van_belt TEXT,
              solar TEXT,
              air_accu TEXT,
              battery_charger TEXT,
              tegangan_battery TEXT,
              tegangan_ff TEXT,
              tegangan_fn TEXT,
              frekuensi TEXT,
              cos_phi TEXT,
              rpm_motor TEXT,
              hour_on TEXT,
              hour_off TEXT,
              temp_mesin TEXT,
              temp_cooler TEXT,
              temp_oli TEXT,
              pelaksana_1 TEXT,
              pelaksana_2 TEXT,
              pelaksana_3 TEXT,
              pelaksana_4 TEXT,
              koordinator TEXT,
              catatan TEXT
            )
          ''');
        }
      },
    );
  }

  static Future<void> simpan(GensetModel data) async {
    final db = await database;
    
    // Ambil data pelaksana (maksimal 4)
    String p1 = data.pelaksana.isNotEmpty ? data.pelaksana[0] : '';
    String p2 = data.pelaksana.length > 1 ? data.pelaksana[1] : '';
    String p3 = data.pelaksana.length > 2 ? data.pelaksana[2] : '';
    String p4 = data.pelaksana.length > 3 ? data.pelaksana[3] : '';
    
    // Cari koordinator (biasanya diawali dengan "Koordinator: ")
    String koordinator = '';
    for (var p in data.pelaksana) {
      if (p.startsWith('Koordinator:')) {
        koordinator = p.replaceFirst('Koordinator:', '').trim();
        break;
      }
    }

    await db.insert(
      'genset_pengujian',
      {
        'id': data.id,
        'tanggal': data.tanggal.toIso8601String(),
        'gedung': data.gedung,
        'oli_mesin': data.radioSebelum['Level Oli Mesin'] ?? '',
        'pemanas_oli': data.radioSebelum['Pemanas Oli'] ?? '',
        'air_radiator': data.radioSebelum['Air Radiator'] ?? '',
        'van_belt': data.radioSebelum['Van Belt'] ?? '',
        'solar': data.radioSebelum['Bahan Bakar/Solar'] ?? '',
        'air_accu': data.radioSebelum['Level Air Accu'] ?? '',
        'battery_charger': data.angkaSaat['Battery Charger'] ?? '',
        'tegangan_battery': data.angkaSaat['Tegangan Battery'] ?? '',
        'tegangan_ff': data.angkaSaat['Tegangan Output F/F'] ?? '',
        'tegangan_fn': data.angkaSaat['Tegangan Output F/N'] ?? '',
        'frekuensi': data.angkaSaat['Frekuensi'] ?? '',
        'cos_phi': data.angkaSaat['Cos Phi'] ?? '',
        'rpm_motor': data.angkaSaat['Rpm Motor'] ?? '',
        'hour_on': data.angkaSaat['Hour meter ON'] ?? '',
        'hour_off': data.angkaSaat['Hour meter OFF'] ?? '',
        'temp_mesin': data.angkaSaat['Temperatur Mesin'] ?? '',
        'temp_cooler': data.angkaSaat['Temperatur Air Cooler'] ?? '',
        'temp_oli': data.angkaSaat['Temperatur Oli'] ?? '',
        'pelaksana_1': p1,
        'pelaksana_2': p2,
        'pelaksana_3': p3,
        'pelaksana_4': p4,
        'koordinator': koordinator,
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
      final map = maps[i];
      
      // Susun kembali pelaksana
      List<String> pelaksana = [];
      if (map['pelaksana_1'] != null && map['pelaksana_1'].toString().isNotEmpty) pelaksana.add(map['pelaksana_1']);
      if (map['pelaksana_2'] != null && map['pelaksana_2'].toString().isNotEmpty) pelaksana.add(map['pelaksana_2']);
      if (map['pelaksana_3'] != null && map['pelaksana_3'].toString().isNotEmpty) pelaksana.add(map['pelaksana_3']);
      if (map['pelaksana_4'] != null && map['pelaksana_4'].toString().isNotEmpty) pelaksana.add(map['pelaksana_4']);
      if (map['koordinator'] != null && map['koordinator'].toString().isNotEmpty) {
        pelaksana.add('Koordinator: ${map['koordinator']}');
      }

      return GensetModel(
        id: map['id'],
        tanggal: DateTime.parse(map['tanggal']),
        gedung: map['gedung'],
        radioSebelum: {
          'Level Oli Mesin': map['oli_mesin'] ?? '',
          'Pemanas Oli': map['pemanas_oli'] ?? '',
          'Air Radiator': map['air_radiator'] ?? '',
          'Van Belt': map['van_belt'] ?? '',
          'Bahan Bakar/Solar': map['solar'] ?? '',
          'Level Air Accu': map['air_accu'] ?? '',
        },
        angkaSaat: {
          'Battery Charger': map['battery_charger'] ?? '',
          'Tegangan Battery': map['tegangan_battery'] ?? '',
          'Tegangan Output F/F': map['tegangan_ff'] ?? '',
          'Tegangan Output F/N': map['tegangan_fn'] ?? '',
          'Frekuensi': map['frekuensi'] ?? '',
          'Cos Phi': map['cos_phi'] ?? '',
          'Rpm Motor': map['rpm_motor'] ?? '',
          'Hour meter ON': map['hour_on'] ?? '',
          'Hour meter OFF': map['hour_off'] ?? '',
          'Temperatur Mesin': map['temp_mesin'] ?? '',
          'Temperatur Air Cooler': map['temp_cooler'] ?? '',
          'Temperatur Oli': map['temp_oli'] ?? '',
        },
        pelaksana: pelaksana,
        catatan: map['catatan'] ?? '',
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
      final hourOff = result.first['hour_off'];
      if (hourOff != null && hourOff.toString().trim().isNotEmpty && hourOff != '-') {
        return hourOff.toString();
      }
    }
    return null;
  }

  // ==========================================
  // EKSPOR DATABASE (TABEL BARU)
  // ==========================================
  static Future<File?> eksporDatabase({
    DateTime? filterTanggal,
    int? filterBulan,
    int? filterTahun,
    List<String>? filterGedungList,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
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
    if (filterGedungList != null && filterGedungList.isNotEmpty) {
      final placeholders = List.filled(filterGedungList.length, '?').join(',');
      conditions.add('gedung IN ($placeholders)');
      whereArgs.addAll(filterGedungList);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      // Menambahkan ORDER BY tanggal agar urut berdasarkan tanggal pengujian
      'SELECT * FROM genset_pengujian $whereClause ORDER BY tanggal ASC',
      whereArgs,
    );
    
    if (maps.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final tempPath = join(tempDir.path, 'ekspor_genset.db');
    final tempFile = File(tempPath);
    if (await tempFile.exists()) await tempFile.delete();

    // Buat database baru dengan struktur tabel yang SAMA (kolom jelas)
    final tempDb = await openDatabase(tempPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
          CREATE TABLE genset_pengujian (
            id TEXT PRIMARY KEY,
            tanggal TEXT,
            gedung TEXT,
            oli_mesin TEXT,
            pemanas_oli TEXT,
            air_radiator TEXT,
            van_belt TEXT,
            solar TEXT,
            air_accu TEXT,
            battery_charger TEXT,
            tegangan_battery TEXT,
            tegangan_ff TEXT,
            tegangan_fn TEXT,
            frekuensi TEXT,
            cos_phi TEXT,
            rpm_motor TEXT,
            hour_on TEXT,
            hour_off TEXT,
            temp_mesin TEXT,
            temp_cooler TEXT,
            temp_oli TEXT,
            pelaksana_1 TEXT,
            pelaksana_2 TEXT,
            pelaksana_3 TEXT,
            pelaksana_4 TEXT,
            koordinator TEXT,
            catatan TEXT
          )
        ''');
    });

    for (var map in maps) {
      await tempDb.insert('genset_pengujian', map);
    }
    await tempDb.close();

    return tempFile;
  }
}