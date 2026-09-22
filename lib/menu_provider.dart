import 'dart:io';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'database_helper.dart';

class MenuProvider with ChangeNotifier {
  static final List<ProductCategory> _defaultCategories = [
    ProductCategory(id: 'C1', name: 'Makanan'),
    ProductCategory(id: 'C2', name: 'Kopi'),
    ProductCategory(id: 'C3', name: 'Minuman'),
    ProductCategory(id: 'C4', name: 'Snacks'),
    ProductCategory(id: 'C5', name: 'Pastry'),
  ];

  static final List<Product> _defaultProducts = [
    Product(
      id: '1',
      categoryId: 'C1',
      name: 'Beef Roasted',
      basePrice: 75000,
      imagePath: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '2',
      categoryId: 'C1',
      name: 'Fried Rice',
      basePrice: 55000,
      imagePath: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=500&q=80',
      isAvailable: true,
      modifiers: [
        ProductModifier(id: 'M_PEDAS', name: 'Level Pedas', options: [
          ModifierOption(name: 'Tidak Pedas', additionalPrice: 0),
          ModifierOption(name: 'Sedang', additionalPrice: 0),
          ModifierOption(name: 'Ekstra Pedas (+Rp3.000)', additionalPrice: 3000),
        ])
      ],
    ),
    Product(
      id: '3',
      categoryId: 'C1',
      name: 'Chicken',
      basePrice: 75000,
      imagePath: 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '4',
      categoryId: 'C1',
      name: 'Fried Catfish',
      basePrice: 25000,
      imagePath: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '5',
      categoryId: 'C1',
      name: 'Chicken Noodles',
      basePrice: 29125,
      imagePath: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '6',
      categoryId: 'C1',
      name: 'Chicken Cheese',
      basePrice: 125000,
      imagePath: 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '7',
      categoryId: 'C1',
      name: 'Fried Rice Special',
      basePrice: 35000,
      imagePath: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '8',
      categoryId: 'C1',
      name: 'Happiness Pizza',
      basePrice: 125000,
      imagePath: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '9',
      categoryId: 'C2',
      name: 'Espresso',
      basePrice: 15000,
      imagePath: 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=500&q=80',
      isAvailable: true,
      modifiers: [
        ProductModifier(id: 'M1', name: 'Extra Shot', options: [
          ModifierOption(name: 'Single', additionalPrice: 0),
          ModifierOption(name: 'Double (+Rp5.000)', additionalPrice: 5000),
        ])
      ],
    ),
    Product(
      id: '10',
      categoryId: 'C2',
      name: 'Caffe Latte',
      basePrice: 25000,
      imagePath: 'https://images.unsplash.com/photo-1570968915860-54d5c301fa9f?w=500&q=80',
      isAvailable: true,
      modifiers: [
        ProductModifier(id: 'M2', name: 'Susu', options: [
          ModifierOption(name: 'Fresh Milk', additionalPrice: 0),
          ModifierOption(name: 'Oat Milk (+Rp8.000)', additionalPrice: 8000),
        ]),
        ProductModifier(id: 'M3', name: 'Suhu', options: [
          ModifierOption(name: 'Hot', additionalPrice: 0),
          ModifierOption(name: 'Ice', additionalPrice: 0),
        ])
      ],
    ),
    Product(
      id: '11',
      categoryId: 'C2',
      name: 'Caramel Macchiato',
      basePrice: 32000,
      imagePath: 'https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '12',
      categoryId: 'C3',
      name: 'Matcha Iced',
      basePrice: 28000,
      imagePath: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '13',
      categoryId: 'C3',
      name: 'Fresh Lemon Tea',
      basePrice: 18000,
      imagePath: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '14',
      categoryId: 'C4',
      name: 'French Fries',
      basePrice: 22000,
      imagePath: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&q=80',
      isAvailable: true,
    ),
    Product(
      id: '15',
      categoryId: 'C5',
      name: 'Croissant',
      basePrice: 20000,
      imagePath: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500&q=80',
      isAvailable: true,
    ),
  ];

  List<ProductCategory> _categories = List.from(_defaultCategories);
  List<Product> _products = List.from(_defaultProducts);
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<ProductCategory> get categories => _categories;
  List<Product> get products => _products;

  MenuProvider() {
    loadMenuFromDb();
  }

  Future<void> loadMenuFromDb() async {
    if (kIsWeb) return;
    try {
      _isLoading = true;
      final seeded = await DatabaseHelper.instance.isMenuSeeded();
      final dbCategories = await DatabaseHelper.instance.getAllCategories();
      final dbProducts = await DatabaseHelper.instance.getAllProducts();

      if (!seeded || dbProducts.isEmpty) {
        await DatabaseHelper.instance.seedInitialMenu(_defaultCategories, _defaultProducts);
        _categories = List.from(_defaultCategories);
        _products = List.from(_defaultProducts);
      } else if (dbCategories.length <= 3 && !dbCategories.any((c) => c.name.toLowerCase() == 'makanan')) {
        // Upgrade database lama ke katalog baru yang kaya makanan & kopi
        await DatabaseHelper.instance.seedInitialMenu(_defaultCategories, _defaultProducts);
        _categories = List.from(_defaultCategories);
        _products = List.from(_defaultProducts);
      } else {
        _categories = dbCategories;
        _products = dbProducts;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loadMenuFromDb: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(ProductCategory category) async {
    _categories.add(category);
    notifyListeners();
    if (!kIsWeb) {
      try {
        await DatabaseHelper.instance.insertCategory(category);
      } catch (e) {
        debugPrint('Error saving category to DB: $e');
      }
    }
  }

  Future<void> updateCategory(String id, String newName) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index] = ProductCategory(id: id, name: newName);
      notifyListeners();
      if (!kIsWeb) {
        try {
          await DatabaseHelper.instance.updateCategory(id, newName);
        } catch (e) {
          debugPrint('Error updating category in DB: $e');
        }
      }
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    if (!kIsWeb) {
      try {
        await DatabaseHelper.instance.deleteCategory(id);
      } catch (e) {
        debugPrint('Error deleting category from DB: $e');
      }
    }
  }

  Future<void> addProduct(Product product) async {
    _products.add(product);
    notifyListeners();
    if (!kIsWeb) {
      try {
        await DatabaseHelper.instance.insertProduct(product);
      } catch (e) {
        debugPrint('Error saving product to DB: $e');
      }
    }
  }

  Future<void> updateProduct(int index, Product product) async {
    if (index >= 0 && index < _products.length) {
      _products[index] = product;
      notifyListeners();
      if (!kIsWeb) {
        try {
          await DatabaseHelper.instance.updateProduct(product);
        } catch (e) {
          debugPrint('Error updating product in DB: $e');
        }
      }
    }
  }

  Future<void> deleteProduct(int index) async {
    if (index >= 0 && index < _products.length) {
      final product = _products.removeAt(index);
      notifyListeners();
      if (!kIsWeb) {
        try {
          await DatabaseHelper.instance.deleteProduct(product.id);
          // Hapus file fisik gambar jika merupakan file lokal internal
          if (product.imagePath.isNotEmpty &&
              !product.imagePath.startsWith('http://') &&
              !product.imagePath.startsWith('https://')) {
            try {
              final file = File(product.imagePath);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              debugPrint('Error deleting product image file: $e');
            }
          }
        } catch (e) {
          debugPrint('Error deleting product from DB: $e');
        }
      }
    }
  }

  Future<void> toggleProductAvailability(int index) async {
    if (index >= 0 && index < _products.length) {
      final current = _products[index];
      final newAvailability = !current.isAvailable;
      _products[index] = Product(
        id: current.id,
        categoryId: current.categoryId,
        name: current.name,
        basePrice: current.basePrice,
        imagePath: current.imagePath,
        isAvailable: newAvailability,
        modifiers: current.modifiers,
      );
      notifyListeners();
      if (!kIsWeb) {
        try {
          await DatabaseHelper.instance.updateProductAvailability(current.id, newAvailability);
        } catch (e) {
          debugPrint('Error toggling product availability in DB: $e');
        }
      }
    }
  }
}
