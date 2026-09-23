import 'package:flutter/material.dart';
import 'models.dart';

// Model khusus untuk membungkus transaksi menjadi tiket dapur
class KitchenOrder {
  final TransactionModel transaction;
  bool isCompleted;

  KitchenOrder({required this.transaction, this.isCompleted = false});
}

class KitchenProvider with ChangeNotifier {
  final List<KitchenOrder> _orders = [];

  // Getter untuk memisahkan daftar pesanan
  List<KitchenOrder> get pendingOrders => _orders.where((o) => !o.isCompleted).toList();
  List<KitchenOrder> get completedOrders => _orders.where((o) => o.isCompleted).toList();

  // Fungsi ini dipanggil oleh Kasir saat pembayaran berhasil
  void addOrder(TransactionModel trx) {
    _orders.add(KitchenOrder(transaction: trx));
    notifyListeners(); // Memperbarui UI dapur secara real-time
  }

  // Fungsi ini dipanggil oleh Koki/Barista saat pesanan selesai
  void markAsCompleted(String transactionId) {
    final index = _orders.indexWhere((o) => o.transaction.id == transactionId);
    if (index != -1) {
      _orders[index].isCompleted = true;
      notifyListeners(); // Memindahkan tiket ke kolom "Selesai"
    }
  }

  // Membersihkan pesanan yang sudah selesai dimasak
  void clearCompletedOrders() {
    _orders.removeWhere((o) => o.isCompleted);
    notifyListeners();
  }

  // Opsional: Untuk membersihkan layar dapur saat ganti shift
  void clearAllOrders() {
    _orders.clear();
    notifyListeners();
  }
}