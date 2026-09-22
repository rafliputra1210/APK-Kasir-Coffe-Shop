import 'package:flutter/foundation.dart';
import 'models.dart';
import 'database_helper.dart';

class ShiftProvider with ChangeNotifier {
  bool _isShiftOpened = false;
  String? _currentShiftId;
  String _cashierName = 'Kasir';
  double _initialCapital = 100000;
  double _totalSales = 0;
  int _transactionCount = 0;
  DateTime? _shiftStartTime;
  DateTime? _lastShiftEndTime;
  List<ShiftRecord> _shiftHistory = [];

  bool get isShiftOpened => _isShiftOpened;
  String? get currentShiftId => _currentShiftId;
  String get cashierName => _cashierName;
  double get initialCapital => _initialCapital;
  double get totalSales => _totalSales;
  int get transactionCount => _transactionCount;
  DateTime? get shiftStartTime => _shiftStartTime;
  DateTime? get lastShiftEndTime => _lastShiftEndTime;
  double get finalCashTotal => _initialCapital + _totalSales;
  List<ShiftRecord> get shiftHistory => _shiftHistory;

  ShiftProvider() {
    loadActiveShiftFromDb();
  }

  Future<void> loadActiveShiftFromDb() async {
    if (kIsWeb) return;
    try {
      final active = await DatabaseHelper.instance.getActiveShift();
      if (active != null) {
        _isShiftOpened = true;
        _currentShiftId = active.id;
        _cashierName = active.cashierName;
        _initialCapital = active.initialCapital;
        _totalSales = active.totalSales;
        _transactionCount = active.transactionCount;
        _shiftStartTime = active.startTime;
      }
      final all = await DatabaseHelper.instance.getAllShifts();
      _shiftHistory = all.where((s) => !s.isOpen).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loadActiveShiftFromDb: $e');
    }
  }

  Future<void> openShift(double capital, {String cashierName = 'Kasir'}) async {
    _isShiftOpened = true;
    _initialCapital = capital;
    _totalSales = 0;
    _transactionCount = 0;
    _cashierName = cashierName;
    _shiftStartTime = DateTime.now();
    _currentShiftId = 'SHIFT-${_shiftStartTime!.millisecondsSinceEpoch}';
    notifyListeners();

    if (!kIsWeb) {
      try {
        final record = ShiftRecord(
          id: _currentShiftId!,
          cashierName: cashierName,
          startTime: _shiftStartTime!,
          initialCapital: capital,
          totalSales: 0,
          transactionCount: 0,
          finalCashTotal: capital,
          isOpen: true,
        );
        await DatabaseHelper.instance.insertShift(record);
      } catch (e) {
        debugPrint('Error inserting shift to DB: $e');
      }
    }
  }

  Future<void> recordTransaction(double amount) async {
    _totalSales += amount;
    _transactionCount += 1;
    notifyListeners();

    if (!kIsWeb && _currentShiftId != null) {
      try {
        await DatabaseHelper.instance.updateShiftProgress(
          shiftId: _currentShiftId!,
          totalSales: _totalSales,
          transactionCount: _transactionCount,
          finalCashTotal: finalCashTotal,
        );
      } catch (e) {
        debugPrint('Error updating shift progress: $e');
      }
    }
  }

  Future<void> closeShift({String cashierName = 'Kasir'}) async {
    if (_shiftStartTime != null) {
      final now = DateTime.now();
      _lastShiftEndTime = now;
      final closedRecord = ShiftRecord(
        id: _currentShiftId ?? 'SHIFT-${now.millisecondsSinceEpoch}',
        cashierName: cashierName,
        startTime: _shiftStartTime!,
        endTime: now,
        initialCapital: _initialCapital,
        totalSales: _totalSales,
        transactionCount: _transactionCount,
        finalCashTotal: finalCashTotal,
        isOpen: false,
      );
      _shiftHistory.insert(0, closedRecord);

      if (!kIsWeb && _currentShiftId != null) {
        try {
          await DatabaseHelper.instance.closeShiftRecord(
            shiftId: _currentShiftId!,
            endTime: now,
            finalCashTotal: finalCashTotal,
          );
        } catch (e) {
          debugPrint('Error closing shift in DB: $e');
        }
      }
    }

    _isShiftOpened = false;
    _currentShiftId = null;
    _totalSales = 0;
    _transactionCount = 0;
    _shiftStartTime = null;
    notifyListeners();
  }
}
