import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('pos_coffee.db');
    return _database!;
  }

  Future<Database?> _initDB(String filePath) async {
    if (kIsWeb) return null;
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 3,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } catch (e) {
      debugPrint('Database init error: $e');
      return null;
    }
  }

  Future _createDB(Database db, int version) async {
    // Tabel Transaksi Utama
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        cashierName TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        paymentAmount REAL NOT NULL,
        changeAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        tableNumber TEXT,
        shiftStartTime TEXT,
        isSynced INTEGER NOT NULL
      )
    ''');

    // Tabel Detail Item Keranjang
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        modifier TEXT,
        total_price REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');

    await _createMenuTables(db);
    await _createUserAndShiftTables(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createMenuTables(db);
    }
    if (oldVersion < 3) {
      await _createUserAndShiftTables(db);
    }
  }

  Future<void> _createUserAndShiftTables(Database db) async {
    // Tabel Pengguna (Admin & Kasir)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        pin TEXT NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // Tabel Shift Kasir
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shifts (
        id TEXT PRIMARY KEY,
        cashierName TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        initialCapital REAL NOT NULL,
        totalSales REAL NOT NULL,
        transactionCount INTEGER NOT NULL,
        finalCashTotal REAL NOT NULL,
        isOpen INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createMenuTables(Database db) async {
    // Tabel Kategori Produk
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    // Tabel Produk Menu
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        name TEXT NOT NULL,
        basePrice REAL NOT NULL,
        imagePath TEXT,
        isAvailable INTEGER NOT NULL,
        modifiers TEXT
      )
    ''');

    // Tabel Pengaturan / Flag App
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // --- Transaksi ---
  Future<void> insertTransaction(TransactionModel trx) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;

      Batch batch = db.batch();
      batch.insert('transactions', trx.toMap());
      
      for (var item in trx.items) {
        batch.insert('transaction_items', {
          'transaction_id': trx.id,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'modifier': item.modifier,
          'total_price': item.totalPrice,
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error insertTransaction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    if (kIsWeb) return [];
    try {
      final db = await instance.database;
      if (db == null) return [];
      return await db.query('transactions', orderBy: 'date DESC');
    } catch (e) {
      debugPrint('Error getAllTransactions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionItems(String trxId) async {
    if (kIsWeb) return [];
    try {
      final db = await instance.database;
      if (db == null) return [];
      return await db.query('transaction_items', where: 'transaction_id = ?', whereArgs: [trxId]);
    } catch (e) {
      debugPrint('Error getTransactionItems: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUnsyncedTransactions() async {
    if (kIsWeb) return [];
    try {
      final db = await instance.database;
      if (db == null) return [];
      return await db.query('transactions', where: 'isSynced = ?', whereArgs: [0]);
    } catch (e) {
      debugPrint('Error getUnsyncedTransactions: $e');
      return [];
    }
  }

  Future<void> markAsSynced(String transactionId) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.update(
        'transactions',
        {'isSynced': 1},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    } catch (e) {
      debugPrint('Error markAsSynced: $e');
    }
  }

  // --- App Settings (Flags) ---
  Future<bool> isMenuSeeded() async {
    if (kIsWeb) return false;
    try {
      final db = await instance.database;
      if (db == null) return false;
      final result = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['menu_seeded'],
      );
      if (result.isNotEmpty && result.first['value'] == '1') {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error isMenuSeeded: $e');
      return false;
    }
  }

  Future<void> setMenuSeeded() async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.insert(
        'app_settings',
        {'key': 'menu_seeded', 'value': '1'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error setMenuSeeded: $e');
    }
  }

  // --- Seed Initial Data ---
  Future<void> seedInitialMenu(List<ProductCategory> categories, List<Product> products) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      
      Batch batch = db.batch();
      for (var cat in categories) {
        batch.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var prod in products) {
        batch.insert('products', prod.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      batch.insert('app_settings', {'key': 'menu_seeded', 'value': '1'}, conflictAlgorithm: ConflictAlgorithm.replace);
      
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error seedInitialMenu: $e');
    }
  }

  // --- Categories CRUD ---
  Future<List<ProductCategory>> getAllCategories() async {
    if (kIsWeb) return [];
    try {
      final db = await instance.database;
      if (db == null) return [];
      final result = await db.query('categories');
      return result.map((c) => ProductCategory.fromMap(c)).toList();
    } catch (e) {
      debugPrint('Error getAllCategories: $e');
      return [];
    }
  }

  Future<void> insertCategory(ProductCategory category) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.insert(
        'categories',
        category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error insertCategory: $e');
    }
  }

  Future<void> updateCategory(String id, String newName) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.update(
        'categories',
        {'name': newName},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error updateCategory: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleteCategory: $e');
    }
  }

  // --- Products CRUD ---
  Future<List<Product>> getAllProducts() async {
    if (kIsWeb) return [];
    try {
      final db = await instance.database;
      if (db == null) return [];
      final result = await db.query('products');
      return result.map((p) => Product.fromMap(p)).toList();
    } catch (e) {
      debugPrint('Error getAllProducts: $e');
      return [];
    }
  }

  Future<void> insertProduct(Product product) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error insertProduct: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    } catch (e) {
      debugPrint('Error updateProduct: $e');
    }
  }

  Future<void> updateProductAvailability(String productId, bool isAvailable) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.update(
        'products',
        {'isAvailable': isAvailable ? 1 : 0},
        where: 'id = ?',
        whereArgs: [productId],
      );
    } catch (e) {
      debugPrint('Error updateProductAvailability: $e');
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );
    } catch (e) {
      debugPrint('Error deleteProduct: $e');
    }
  }

  // ==========================================
  // --- USERS (Admin & Kasir) CRUD ---
  // ==========================================
  Future<bool> isUsersSeeded() async {
    if (kIsWeb) return false;
    try {
      final db = await instance.database;
      if (db == null) return false;
      final result = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['users_seeded'],
      );
      return result.isNotEmpty && result.first['value'] == '1';
    } catch (e) {
      debugPrint('Error isUsersSeeded: $e');
      return false;
    }
  }

  Future<void> seedInitialUsers(List<UserModel> defaultUsers) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      Batch batch = db.batch();
      for (var user in defaultUsers) {
        batch.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      batch.insert('app_settings', {'key': 'users_seeded', 'value': '1'}, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('Error seedInitialUsers: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    if (kIsWeb) return [];
    try {
      final db = await instance.database;
      if (db == null) return [];
      final result = await db.query('users');
      return result.map((u) => UserModel.fromMap(u)).toList();
    } catch (e) {
      debugPrint('Error getAllUsers: $e');
      return [];
    }
  }

  Future<void> insertUser(UserModel user) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error insertUser: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      debugPrint('Error updateUser: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleteUser: $e');
    }
  }

  // ==========================================
  // --- SHIFTS PERSISTENCE ---
  // ==========================================
  Future<ShiftRecord?> getActiveShift() async {
    if (kIsWeb) return null;
    try {
      final db = await instance.database;
      if (db == null) return null;
      final result = await db.query(
        'shifts',
        where: 'isOpen = ?',
        whereArgs: [1],
        orderBy: 'startTime DESC',
        limit: 1,
      );
      if (result.isNotEmpty) {
        return ShiftRecord.fromMap(result.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getActiveShift: $e');
      return null;
    }
  }

  Future<void> insertShift(ShiftRecord shift) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.insert('shifts', shift.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error insertShift: $e');
    }
  }

  Future<void> updateShiftProgress({
    required String shiftId,
    required double totalSales,
    required int transactionCount,
    required double finalCashTotal,
  }) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.update(
        'shifts',
        {
          'totalSales': totalSales,
          'transactionCount': transactionCount,
          'finalCashTotal': finalCashTotal,
        },
        where: 'id = ?',
        whereArgs: [shiftId],
      );
    } catch (e) {
      debugPrint('Error updateShiftProgress: $e');
    }
  }

  Future<void> closeShiftRecord({
    required String shiftId,
    required DateTime endTime,
    required double finalCashTotal,
  }) async {
    if (kIsWeb) return;
    try {
      final db = await instance.database;
      if (db == null) return;
      await db.update(
        'shifts',
        {
          'endTime': endTime.toIso8601String(),
          'finalCashTotal': finalCashTotal,
          'isOpen': 0,
        },
        where: 'id = ?',
        whereArgs: [shiftId],
      );
    } catch (e) {
      debugPrint('Error closeShiftRecord: $e');
    }
  }

  Future<List<ShiftRecord>> getAllShifts() async {
    if (kIsWeb) return [];
    try {
      final db = await instance.database;
      if (db == null) return [];
      final result = await db.query('shifts', orderBy: 'startTime DESC');
      return result.map((s) => ShiftRecord.fromMap(s)).toList();
    } catch (e) {
      debugPrint('Error getAllShifts: $e');
      return [];
    }
  }
}