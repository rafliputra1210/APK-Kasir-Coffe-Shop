import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'database_helper.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  static String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  static bool isPinMatch(String enteredPin, String storedPin) {
    if (storedPin == enteredPin) return true; // Plaintext match
    if (storedPin == hashPin(enteredPin)) return true; // SHA-256 match
    return false;
  }

  static final List<UserModel> _defaultUsers = [
    UserModel(
      id: 'A01',
      username: 'Admin Utama',
      pin: hashPin('123456'),
      role: UserRole.admin,
      status: UserStatus.aktif,
    ),
    UserModel(
      id: 'K01',
      username: 'Kasir A',
      pin: hashPin('111111'),
      role: UserRole.kasir,
      status: UserStatus.aktif,
    ),
    UserModel(
      id: 'K02',
      username: 'Kasir B',
      pin: hashPin('222222'),
      role: UserRole.kasir,
      status: UserStatus.blokir,
    ),
  ];

  List<UserModel> _users = List.from(_defaultUsers);

  List<UserModel> get users => _users;
  List<UserModel> get cashiers => _users.where((u) => u.role == UserRole.kasir).toList();

  AuthProvider() {
    loadUsersFromDb();
  }

  Future<void> loadUsersFromDb() async {
    if (kIsWeb) return;
    try {
      final seeded = await DatabaseHelper.instance.isUsersSeeded();
      if (!seeded) {
        await DatabaseHelper.instance.seedInitialUsers(_defaultUsers);
        _users = List.from(_defaultUsers);
      } else {
        final dbUsers = await DatabaseHelper.instance.getAllUsers();
        if (dbUsers.isNotEmpty) {
          _users = dbUsers;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loadUsersFromDb: $e');
    }
  }

  bool login(String pin) {
    try {
      final user = _users.firstWhere(
        (u) => isPinMatch(pin, u.pin) && u.status == UserStatus.aktif,
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // --- CRUD Kasir untuk Admin ---
  Future<void> addCashier(String username, String pin) async {
    final newId = 'K${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final newCashier = UserModel(
      id: newId,
      username: username,
      pin: hashPin(pin),
      role: UserRole.kasir,
      status: UserStatus.aktif,
    );
    _users.add(newCashier);
    notifyListeners();

    if (!kIsWeb) {
      try {
        await DatabaseHelper.instance.insertUser(newCashier);
      } catch (e) {
        debugPrint('Error inserting cashier to DB: $e');
      }
    }
  }

  Future<void> toggleUserStatus(String userId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final current = _users[index];
      final newStatus = current.status == UserStatus.aktif ? UserStatus.nonAktif : UserStatus.aktif;
      final updated = UserModel(
        id: current.id,
        username: current.username,
        pin: current.pin,
        role: current.role,
        status: newStatus,
      );
      _users[index] = updated;
      notifyListeners();

      if (!kIsWeb) {
        try {
          await DatabaseHelper.instance.updateUser(updated);
        } catch (e) {
          debugPrint('Error updating user status in DB: $e');
        }
      }
    }
  }

  Future<void> resetUserPin(String userId, String newPin) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final current = _users[index];
      final updated = UserModel(
        id: current.id,
        username: current.username,
        pin: hashPin(newPin),
        role: current.role,
        status: current.status,
      );
      _users[index] = updated;
      notifyListeners();

      if (!kIsWeb) {
        try {
          await DatabaseHelper.instance.updateUser(updated);
        } catch (e) {
          debugPrint('Error resetting user PIN in DB: $e');
        }
      }
    }
  }

  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    notifyListeners();

    if (!kIsWeb) {
      try {
        await DatabaseHelper.instance.deleteUser(userId);
      } catch (e) {
        debugPrint('Error deleting user from DB: $e');
      }
    }
  }
}