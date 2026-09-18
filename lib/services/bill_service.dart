import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/bill.dart';
import 'transaction_service.dart';

class BillService extends ChangeNotifier {
  final List<Bill> _bills = [];

  static const String _boxName = 'bills';
  static const String _key = 'data';

  /// Buat instance baru dan muat data tagihan dari Hive.
  static Future<BillService> load() async {
    final box = await Hive.openBox(_boxName);
    return BillService._fromBox(box);
  }

  BillService._fromBox(Box box) {
    final raw = box.get(_key);
    if (raw != null && raw is List && raw.isNotEmpty) {
      _bills.addAll(raw.map((e) => Bill.fromMap(e as Map)).toList());
    }
  }

  /// Konstruktor kosong untuk testing (tanpa Hive)
  BillService();

  // ── Hive Helpers ──────────────────────────────────────────────────────────

  Future<void> _persist() async {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box(_boxName);
    box.put(_key, _bills.map((b) => b.toMap()).toList());
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  List<Bill> get bills => List.unmodifiable(_bills);

  /// Tagihan belum dibayar, diurutkan jatuh tempo terdekat
  List<Bill> get unpaidBills {
    final list = _bills.where((b) => !b.isPaid).toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  /// Tagihan sudah dibayar, diurutkan paling baru
  List<Bill> get paidBills {
    final list = _bills.where((b) => b.isPaid).toList();
    list.sort((a, b) => (b.paidAt ?? b.createdAt).compareTo(a.paidAt ?? a.createdAt));
    return list;
  }

  /// Jumlah tagihan yang sudah lewat jatuh tempo dan belum dibayar
  int get overdueBillsCount => _bills.where((b) => b.isOverdue).length;

  /// Total nominal tagihan yang belum dibayar
  double get totalUnpaidAmount =>
      unpaidBills.fold(0.0, (sum, b) => sum + b.amount);

  // ── Operations ────────────────────────────────────────────────────────────

  /// Tambah tagihan baru
  void addBill({
    required String name,
    required double amount,
    required DateTime dueDate,
    bool isRecurring = false,
    BillRecurrence? recurrence,
  }) {
    final bill = Bill(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      amount: amount,
      dueDate: dueDate,
      isRecurring: isRecurring,
      recurrence: isRecurring ? recurrence : null,
      isPaid: false,
      paidAt: null,
      createdAt: DateTime.now(),
    );
    _bills.insert(0, bill);
    _persist();
    notifyListeners();
  }

  /// Bayar tagihan:
  /// 1. Catat pengeluaran ke TransactionService
  /// 2. Tandai tagihan ini sebagai lunas
  /// 3. Jika berulang, buat entri tagihan baru untuk periode berikutnya
  void payBill(
    String billId,
    String walletId,
    TransactionService txService,
  ) {
    final index = _bills.indexWhere((b) => b.id == billId);
    if (index == -1) return;
    final bill = _bills[index];
    if (bill.isPaid) return;

    // Catat sebagai pengeluaran
    txService.addExpense(
      bill.amount,
      walletId: walletId,
      title: 'Tagihan: ${bill.name}',
    );

    // Tandai lunas
    _bills[index] = bill.copyWith(isPaid: true, paidAt: DateTime.now());

    // Jika berulang, buat tagihan baru untuk periode selanjutnya
    if (bill.isRecurring && bill.recurrence != null) {
      final nextBill = Bill(
        id: '${DateTime.now().microsecondsSinceEpoch}_r',
        name: bill.name,
        amount: bill.amount,
        dueDate: bill.nextDueDate,
        isRecurring: true,
        recurrence: bill.recurrence,
        isPaid: false,
        paidAt: null,
        createdAt: DateTime.now(),
      );
      _bills.insert(0, nextBill);
    }

    _persist();
    notifyListeners();
  }

  /// Hapus tagihan
  void deleteBill(String id) {
    _bills.removeWhere((b) => b.id == id);
    _persist();
    notifyListeners();
  }
}
