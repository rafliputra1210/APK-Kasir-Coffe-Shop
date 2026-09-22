import 'dart:convert';

// 1. Model untuk Manajemen Akun (Admin & Kasir)
// Mencakup pengaturan status akun (Aktif/Non-aktif/Blokir).
enum UserStatus { aktif, nonAktif, blokir }
enum UserRole { admin, kasir }

class UserModel {
  final String id;
  final String username;
  final String pin; // Digunakan kasir untuk login
  final UserRole role;
  final UserStatus status;

  UserModel({
    required this.id,
    required this.username,
    required this.pin,
    required this.role,
    this.status = UserStatus.aktif,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      pin: json['pin']?.toString() ?? '',
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.kasir,
      status: UserStatus.values.firstWhere(
          (e) => e.name == json['status'], 
          orElse: () => UserStatus.aktif),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'pin': pin,
        'role': role.name,
        'status': status.name,
      };

  Map<String, dynamic> toMap() => toJson();

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel.fromJson(map);
}

// 2. Model untuk Kategori Menu
// Mengelompokkan menu seperti Espresso Based, Manual Brew, Non-Coffee, dan Pastry[cite: 1].
class ProductCategory {
  final String id;
  final String name;

  ProductCategory({required this.id, required this.name});

  factory ProductCategory.fromJson(Map<String, dynamic> json) => ProductCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory ProductCategory.fromMap(Map<String, dynamic> map) => ProductCategory(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
      );
}

// 3. Model untuk Varian (Modifier/Add-on)
// Mengatur tambahan yang mempengaruhi harga (contoh: +Rp5.000 untuk Oat Milk, Ice/Hot, Sugar Level)[cite: 1].
class ProductModifier {
  final String id;
  final String name; // Contoh: "Jenis Susu" atau "Level Gula"
  final List<ModifierOption> options;

  ProductModifier({required this.id, required this.name, required this.options});

  factory ProductModifier.fromJson(Map<String, dynamic> json) {
    var optionsList = json['options'] as List;
    return ProductModifier(
      id: json['id'],
      name: json['name'],
      options: optionsList.map((i) => ModifierOption.fromJson(i)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'options': options.map((e) => e.toJson()).toList(),
      };
}

class ModifierOption {
  final String name; // Contoh: "Oat Milk" atau "Extra Espresso Shot"[cite: 1]
  final double additionalPrice; // Contoh: 5000 atau 3000[cite: 1]

  ModifierOption({required this.name, required this.additionalPrice});

  factory ModifierOption.fromJson(Map<String, dynamic> json) => ModifierOption(
        name: json['name'],
        additionalPrice: (json['additionalPrice'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'additionalPrice': additionalPrice,
      };
}

// 4. Model Utama Produk (Menu)
// Menyimpan item menu beserta foto produk, ketersediaan stok (Tersedia/Habis), dan harga dasar[cite: 1].
class Product {
  final String id;
  final String categoryId;
  final String name;
  final double basePrice; // Harga dasar produk[cite: 1]
  final String imagePath;
  final bool isAvailable; // true = Tersedia, false = Habis[cite: 1]
  final List<ProductModifier> modifiers; // Daftar add-on/modifier produk ini

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.basePrice,
    required this.imagePath,
    this.isAvailable = true,
    this.modifiers = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var modifiersList = json['modifiers'] != null ? json['modifiers'] as List : [];
    return Product(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      imagePath: json['imagePath']?.toString() ?? '',
      isAvailable: json['isAvailable'] is bool
          ? json['isAvailable'] as bool
          : (json['isAvailable'] == 1 || json['isAvailable'] == '1' || json['isAvailable'] == null),
      modifiers: modifiersList.map((i) => ProductModifier.fromJson(Map<String, dynamic>.from(i))).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'basePrice': basePrice,
        'imagePath': imagePath,
        'isAvailable': isAvailable,
        'modifiers': modifiers.map((e) => e.toJson()).toList(),
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'basePrice': basePrice,
        'imagePath': imagePath,
        'isAvailable': isAvailable ? 1 : 0,
        'modifiers': jsonEncode(modifiers.map((e) => e.toJson()).toList()),
      };

  factory Product.fromMap(Map<String, dynamic> map) {
    List<ProductModifier> parsedModifiers = [];
    if (map['modifiers'] != null && (map['modifiers'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(map['modifiers'] as String) as List;
        parsedModifiers = decoded.map((i) => ProductModifier.fromJson(Map<String, dynamic>.from(i))).toList();
      } catch (e) {
        // Fallback jika format salah
      }
    }
    return Product(
      id: map['id']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
      imagePath: map['imagePath']?.toString() ?? '',
      isAvailable: map['isAvailable'] is bool
          ? map['isAvailable'] as bool
          : (map['isAvailable'] == 1 || map['isAvailable'] == '1' || map['isAvailable'] == null),
      modifiers: parsedModifiers,
    );
  }
}
class CartItem {
  final Product product;
  final String modifier;
  final double modifierPrice;
  final String notes;
  int quantity;

  CartItem({
    required this.product,
    this.modifier = '',
    this.modifierPrice = 0,
    this.notes = '',
    this.quantity = 1,
  });

  double get totalPrice => (product.basePrice + modifierPrice) * quantity;
}

class TransactionModel {
  final String id;
  final DateTime date;
  final String cashierName;
  final List<CartItem> items;
  final double totalAmount;
  final double paymentAmount;
  final double changeAmount;
  final String paymentMethod;
  final String? tableNumber;
  final DateTime? shiftStartTime;
  bool isSynced; // Penanda sinkronisasi cloud

  TransactionModel({
    required this.id,
    required this.date,
    required this.cashierName,
    required this.items,
    required this.totalAmount,
    required this.paymentAmount,
    required this.changeAmount,
    required this.paymentMethod,
    this.tableNumber,
    this.shiftStartTime,
    this.isSynced = false,
  });

  // Konversi ke format SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'cashierName': cashierName,
      'totalAmount': totalAmount,
      'paymentAmount': paymentAmount,
      'changeAmount': changeAmount,
      'paymentMethod': paymentMethod,
      'tableNumber': tableNumber,
      'shiftStartTime': shiftStartTime?.toIso8601String(),
      'isSynced': isSynced ? 1 : 0, // SQLite tidak punya boolean, gunakan 1/0
    };
  }
}

class ShiftRecord {
  final String id;
  final String cashierName;
  final DateTime startTime;
  final DateTime? endTime;
  final double initialCapital;
  final double totalSales;
  final int transactionCount;
  final double finalCashTotal;
  final bool isOpen;

  ShiftRecord({
    required this.id,
    required this.cashierName,
    required this.startTime,
    this.endTime,
    required this.initialCapital,
    this.totalSales = 0,
    this.transactionCount = 0,
    required this.finalCashTotal,
    this.isOpen = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cashierName': cashierName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'initialCapital': initialCapital,
      'totalSales': totalSales,
      'transactionCount': transactionCount,
      'finalCashTotal': finalCashTotal,
      'isOpen': isOpen ? 1 : 0,
    };
  }

  factory ShiftRecord.fromMap(Map<String, dynamic> map) {
    return ShiftRecord(
      id: map['id']?.toString() ?? '',
      cashierName: map['cashierName']?.toString() ?? 'Kasir',
      startTime: DateTime.tryParse(map['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: map['endTime'] != null ? DateTime.tryParse(map['endTime'].toString()) : null,
      initialCapital: (map['initialCapital'] as num?)?.toDouble() ?? 0.0,
      totalSales: (map['totalSales'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (map['transactionCount'] as int?) ?? 0,
      finalCashTotal: (map['finalCashTotal'] as num?)?.toDouble() ?? 0.0,
      isOpen: (map['isOpen'] as int? ?? 0) == 1,
    );
  }
}