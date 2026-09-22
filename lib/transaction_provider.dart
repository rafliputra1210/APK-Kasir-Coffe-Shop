import 'package:flutter/foundation.dart';
import 'models.dart';
import 'database_helper.dart';

class TransactionProvider with ChangeNotifier {
  List<TransactionModel> _history = [];
  
  List<TransactionModel> get history => _history;

  TransactionProvider() {
    // Muat data dari SQLite saat aplikasi pertama kali dibuka jika bukan web
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    if (kIsWeb) return; // SQLite tidak didukung di web browser
    try {
      final data = await DatabaseHelper.instance.getAllTransactions();
      
      List<TransactionModel> loaded = [];
      for (var map in data) {
        final itemsData = await DatabaseHelper.instance.getTransactionItems(map['id']);
        List<CartItem> items = itemsData.map((iMap) {
          final qty = iMap['quantity'] as int? ?? 1;
          final totalPrice = (iMap['total_price'] as num?)?.toDouble() ?? 0.0;
          return CartItem(
            product: Product(
              id: '',
              categoryId: '',
              name: iMap['product_name'] ?? '',
              basePrice: qty > 0 ? totalPrice / qty : totalPrice,
              imagePath: '',
            ),
            quantity: qty,
            modifier: iMap['modifier'] ?? '',
            modifierPrice: 0,
          );
        }).toList();

        loaded.add(TransactionModel(
          id: map['id'],
          date: DateTime.parse(map['date']),
          cashierName: map['cashierName'],
          items: items, 
          totalAmount: (map['totalAmount'] as num).toDouble(),
          paymentAmount: (map['paymentAmount'] as num).toDouble(),
          changeAmount: (map['changeAmount'] as num).toDouble(),
          paymentMethod: map['paymentMethod'] ?? 'Tunai',
          tableNumber: map['tableNumber'],
          shiftStartTime: map['shiftStartTime'] != null ? DateTime.tryParse(map['shiftStartTime']) : null,
          isSynced: map['isSynced'] == 1,
        ));
      }
      
      if (loaded.isNotEmpty) {
        _history = loaded;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading transactions from SQLite: $e');
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    // 1. Tambahkan ke memori UI terlebih dahulu agar transaksi langsung tampil di web & perangkat
    _history.insert(0, transaction);
    notifyListeners();

    // 2. Simpan ke database lokal SQLite secara permanen (jika bukan Web / Offline Support)
    if (!kIsWeb) {
      try {
        await DatabaseHelper.instance.insertTransaction(transaction);
      } catch (e) {
        debugPrint('Error inserting to SQLite: $e');
      }
    }
    
    // 3. Panggil sinkronisasi cloud jika bukan Web
    if (!kIsWeb) {
      try {
        syncToCloud();
      } catch (e) {
        debugPrint('Error in syncToCloud: $e');
      }
    }
  }

  // Logika Sinkronisasi Cloud
  Future<void> syncToCloud() async {
    if (kIsWeb) return;
    try {
      final unsynced = await DatabaseHelper.instance.getUnsyncedTransactions();
      if (unsynced.isEmpty) return;

      for (var trxMap in unsynced) {
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          await DatabaseHelper.instance.markAsSynced(trxMap['id']);
          int index = _history.indexWhere((t) => t.id == trxMap['id']);
          if (index != -1) {
            _history[index].isSynced = true;
          }
        } catch (e) {
          debugPrint('Gagal sinkronisasi: ${trxMap['id']}');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error in syncToCloud: $e');
    }
  }
}