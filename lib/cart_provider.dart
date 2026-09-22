import 'package:flutter/material.dart';
import 'models.dart';

class HeldOrder {
  final String id;
  final DateTime createdAt;
  final String orderType;
  final String? tableOrCustomer;
  final List<CartItem> items;
  final double totalAmount;

  HeldOrder({
    required this.id,
    required this.createdAt,
    required this.orderType,
    this.tableOrCustomer,
    required this.items,
    required this.totalAmount,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String _orderType = 'Dine In'; // 'Dine In' atau 'Take Away'
  final double _taxRate = 0.05; // 5% Pajak (sesuai referensi UI)
  final double _serviceCharge = 400.0; // Biaya layanan (sesuai referensi UI)
  final List<HeldOrder> _heldOrders = [];

  List<CartItem> get items => _items;
  String get orderType => _orderType;
  double get taxRate => _taxRate;
  List<HeldOrder> get heldOrders => _heldOrders;

  // Rincian Kalkulasi Harga
  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get taxAmount => subtotal * _taxRate;
  double get serviceCharge => _items.isEmpty ? 0.0 : _serviceCharge;
  double get grandTotal => subtotal + taxAmount + serviceCharge;

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void addToCart(
    Product product, {
    String modifier = '',
    double modPrice = 0,
    String notes = '',
  }) {
    // Cari apakah item dengan modifier & catatan yang sama sudah ada di keranjang
    final index = _items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.modifier == modifier &&
          item.notes == notes,
    );

    if (index != -1) {
      _items[index].quantity += 1;
    } else {
      _items.add(
        CartItem(
          product: product,
          modifier: modifier,
          modifierPrice: modPrice,
          notes: notes,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  void incrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity += 1;
      notifyListeners();
    }
  }

  void decrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // --- Fitur Simpan / Hold Order (Sesuai Tombol Simpan Order) ---
  bool holdCurrentOrder({String? tableOrCustomer}) {
    if (_items.isEmpty) return false;

    final newHeld = HeldOrder(
      id: 'HOLD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      createdAt: DateTime.now(),
      orderType: _orderType,
      tableOrCustomer: tableOrCustomer,
      items: List.from(_items),
      totalAmount: grandTotal,
    );

    _heldOrders.insert(0, newHeld);
    _items.clear();
    notifyListeners();
    return true;
  }

  void restoreHeldOrder(String holdId) {
    final index = _heldOrders.indexWhere((h) => h.id == holdId);
    if (index != -1) {
      final held = _heldOrders.removeAt(index);
      _items.clear();
      _items.addAll(held.items);
      _orderType = held.orderType;
      notifyListeners();
    }
  }

  void deleteHeldOrder(String holdId) {
    _heldOrders.removeWhere((h) => h.id == holdId);
    notifyListeners();
  }
}
