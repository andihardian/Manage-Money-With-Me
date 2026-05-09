import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE kategori (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        nama TEXT NOT NULL,
        jenis TEXT NOT NULL,
        ikon TEXT NOT NULL,
        warna TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        kategori_id INTEGER NOT NULL,
        jumlah REAL NOT NULL,
        jenis TEXT NOT NULL,
        catatan TEXT,
        tanggal TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (kategori_id) REFERENCES kategori(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE anggaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        kategori_id INTEGER NOT NULL,
        jumlah REAL NOT NULL,
        bulan INTEGER NOT NULL,
        tahun INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (kategori_id) REFERENCES kategori(id)
      )
    ''');
  }

  // ===== USER =====
  Future<int> registerUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> emailExists(String email) async {
    final db = await database;
    final result =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty;
  }

  // ===== KATEGORI =====
  Future<int> insertKategori(Map<String, dynamic> kategori) async {
    final db = await database;
    return await db.insert('kategori', kategori);
  }

  Future<List<Map<String, dynamic>>> getKategori(int userId,
      {String? jenis}) async {
    final db = await database;
    if (jenis != null) {
      return await db.query('kategori',
          where: 'user_id = ? AND jenis = ?', whereArgs: [userId, jenis]);
    }
    return await db
        .query('kategori', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> updateKategori(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db
        .update('kategori', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteKategori(int id) async {
    final db = await database;
    return await db.delete('kategori', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertDefaultKategori(int userId) async {
    final defaults = [
      {
        'user_id': userId,
        'nama': 'Gaji',
        'jenis': 'pemasukan',
        'ikon': '💰',
        'warna': '0xFF4CAF50'
      },
      {
        'user_id': userId,
        'nama': 'Freelance',
        'jenis': 'pemasukan',
        'ikon': '💻',
        'warna': '0xFF2196F3'
      },
      {
        'user_id': userId,
        'nama': 'Investasi',
        'jenis': 'pemasukan',
        'ikon': '📈',
        'warna': '0xFF9C27B0'
      },
      {
        'user_id': userId,
        'nama': 'Hadiah',
        'jenis': 'pemasukan',
        'ikon': '🎁',
        'warna': '0xFFFF9800'
      },
      {
        'user_id': userId,
        'nama': 'Makanan',
        'jenis': 'pengeluaran',
        'ikon': '🍜',
        'warna': '0xFFF44336'
      },
      {
        'user_id': userId,
        'nama': 'Transportasi',
        'jenis': 'pengeluaran',
        'ikon': '🚗',
        'warna': '0xFF607D8B'
      },
      {
        'user_id': userId,
        'nama': 'Belanja',
        'jenis': 'pengeluaran',
        'ikon': '🛒',
        'warna': '0xFFE91E63'
      },
      {
        'user_id': userId,
        'nama': 'Hiburan',
        'jenis': 'pengeluaran',
        'ikon': '🎬',
        'warna': '0xFF673AB7'
      },
      {
        'user_id': userId,
        'nama': 'Kesehatan',
        'jenis': 'pengeluaran',
        'ikon': '🏥',
        'warna': '0xFF00BCD4'
      },
      {
        'user_id': userId,
        'nama': 'Tagihan',
        'jenis': 'pengeluaran',
        'ikon': '📄',
        'warna': '0xFFFF5722'
      },
      {
        'user_id': userId,
        'nama': 'Pendidikan',
        'jenis': 'pengeluaran',
        'ikon': '📚',
        'warna': '0xFF795548'
      },
      {
        'user_id': userId,
        'nama': 'Lainnya',
        'jenis': 'pengeluaran',
        'ikon': '📦',
        'warna': '0xFF9E9E9E'
      },
    ];
    for (var k in defaults) {
      await insertKategori(k);
    }
  }

  // ===== TRANSAKSI =====
  Future<int> insertTransaksi(Map<String, dynamic> transaksi) async {
    final db = await database;
    return await db.insert('transaksi', transaksi);
  }

  Future<List<Map<String, dynamic>>> getTransaksi(int userId,
      {String? bulan, String? tahun, String? jenis}) async {
    final db = await database;
    String where = 'transaksi.user_id = ?';
    List<dynamic> whereArgs = [userId];

    if (bulan != null && tahun != null) {
      where += " AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?";
      whereArgs.addAll([bulan.padLeft(2, '0'), tahun]);
    }
    if (jenis != null) {
      where += ' AND transaksi.jenis = ?';
      whereArgs.add(jenis);
    }

    return await db.rawQuery('''
      SELECT transaksi.*, kategori.nama as kategori_nama, 
             kategori.ikon as kategori_ikon, kategori.warna as kategori_warna
      FROM transaksi
      LEFT JOIN kategori ON transaksi.kategori_id = kategori.id
      WHERE $where
      ORDER BY tanggal DESC, transaksi.created_at DESC
    ''', whereArgs);
  }

  Future<int> updateTransaksi(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db
        .update('transaksi', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransaksi(int id) async {
    final db = await database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getRingkasan(int userId,
      {required String bulan, required String tahun}) async {
    final db = await database;

    final pemasukan = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total FROM transaksi
      WHERE user_id = ? AND jenis = 'pemasukan'
      AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?
    ''', [userId, bulan.padLeft(2, '0'), tahun]);

    final pengeluaran = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total FROM transaksi
      WHERE user_id = ? AND jenis = 'pengeluaran'
      AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?
    ''', [userId, bulan.padLeft(2, '0'), tahun]);

    return {
      'pemasukan': pemasukan.first['total'] ?? 0.0,
      'pengeluaran': pengeluaran.first['total'] ?? 0.0,
    };
  }

  Future<List<Map<String, dynamic>>> getTransaksiPerKategori(
      int userId, String jenis,
      {required String bulan, required String tahun}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT kategori.nama, kategori.ikon, kategori.warna,
             COALESCE(SUM(transaksi.jumlah), 0) as total
      FROM transaksi
      LEFT JOIN kategori ON transaksi.kategori_id = kategori.id
      WHERE transaksi.user_id = ? AND transaksi.jenis = ?
      AND strftime('%m', tansaksi.tanggal) = ? AND strftime('%Y', transaksi.tanggal) = ?
      GROUP BY transaksi.kategori_id
      ORDER BY total DESC
    ''', [userId, jenis, bulan.padLeft(2, '0'), tahun]);
  }

  Future<List<Map<String, dynamic>>> getTransaksiHarian(
      int userId, String jenis,
      {required String bulan, required String tahun}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT strftime('%d', tanggal) as hari,
             COALESCE(SUM(jumlah), 0) as total
      FROM transaksi
      WHERE user_id = ? AND jenis = ?
      AND strftime('%m', tanggal) = ? AND strftime('%Y', tanggal) = ?
      GROUP BY hari
      ORDER BY hari ASC
    ''', [userId, jenis, bulan.padLeft(2, '0'), tahun]);
  }

  // ===== ANGGARAN =====
  Future<int> insertAnggaran(Map<String, dynamic> anggaran) async {
    final db = await database;
    return await db.insert('anggaran', anggaran,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAnggaran(
      int userId, int bulan, int tahun) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT anggaran.*, kategori.nama as kategori_nama,
             kategori.ikon as kategori_ikon, kategori.warna as kategori_warna,
             COALESCE((
               SELECT SUM(jumlah) FROM transaksi
               WHERE kategori_id = anggaran.kategori_id
               AND user_id = anggaran.user_id
               AND jenis = 'pengeluaran'
               AND strftime('%m', tanggal) = ?
               AND strftime('%Y', tanggal) = ?
             ), 0) as terpakai
      FROM anggaran
      LEFT JOIN kategori ON anggaran.kategori_id = kategori.id
      WHERE anggaran.user_id = ? AND anggaran.bulan = ? AND anggaran.tahun = ?
    ''', [
      bulan.toString().padLeft(2, '0'),
      tahun.toString(),
      userId,
      bulan,
      tahun
    ]);
  }

  Future<int> deleteAnggaran(int id) async {
    final db = await database;
    return await db.delete('anggaran', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}