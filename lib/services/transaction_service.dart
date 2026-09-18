import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class TransactionService extends ChangeNotifier {
  final List<TransactionRecord> _transactions = [];
  final List<Wallet> _wallets = [];

  static const String _boxTransactions = 'transactions';
  static const String _boxWallets = 'wallets';
  static const String _keyTransactions = 'data';
  static const String _keyWallets = 'data';
  static const String defaultWalletId = 'wallet_cash';

  /// Buat instance baru dan muat data dari Hive.
  /// Gunakan metode ini sebagai pengganti konstruktor biasa saat startup.
  static Future<TransactionService> load() async {
    final txBox = await Hive.openBox(_boxTransactions);
    final walletBox = await Hive.openBox(_boxWallets);
    return TransactionService._fromBoxes(txBox, walletBox);
  }

  TransactionService._fromBoxes(Box txBox, Box walletBox) {
    // Muat dompet dari Hive
    final rawWallets = walletBox.get(_keyWallets);
    if (rawWallets != null && rawWallets is List && rawWallets.isNotEmpty) {
      _wallets.addAll(
        rawWallets.map((e) => Wallet.fromMap(e as Map)).toList(),
      );
    } else {
      _initializeDefaultWallets();
      _saveWallets(walletBox);
    }

    // Muat transaksi dari Hive
    final rawTx = txBox.get(_keyTransactions);
    if (rawTx != null && rawTx is List && rawTx.isNotEmpty) {
      _transactions.addAll(
        rawTx.map((e) => TransactionRecord.fromMap(e as Map)).toList(),
      );
    }
  }

  /// Konstruktor untuk testing (tanpa Hive)
  TransactionService({List<Wallet>? initialWallets}) {
    if (initialWallets != null && initialWallets.isNotEmpty) {
      _wallets.addAll(initialWallets);
    } else {
      _initializeDefaultWallets();
    }
  }

  void _initializeDefaultWallets() {
    if (_wallets.isEmpty) {
      _wallets.addAll([
        Wallet(
          id: 'wallet_cash',
          name: 'Tunai / Cash',
          createdAt: DateTime.now(),
        ),
        Wallet(
          id: 'wallet_brimo',
          name: 'BRImo',
          createdAt: DateTime.now(),
        ),
        Wallet(
          id: 'wallet_dana',
          name: 'DANA',
          createdAt: DateTime.now(),
        ),
      ]);
    }
  }

  // ── Helpers Hive ──────────────────────────────────────────────────────────

  void _saveTransactions(Box box) {
    box.put(_keyTransactions, _transactions.map((t) => t.toMap()).toList());
  }

  void _saveWallets(Box box) {
    box.put(_keyWallets, _wallets.map((w) => w.toMap()).toList());
  }

  /// Simpan semua data ke Hive (panggil setelah setiap perubahan)
  Future<void> _persist() async {
    if (!Hive.isBoxOpen(_boxTransactions) || !Hive.isBoxOpen(_boxWallets)) {
      return;
    }
    final txBox = Hive.box(_boxTransactions);
    final walletBox = Hive.box(_boxWallets);
    _saveTransactions(txBox);
    _saveWallets(walletBox);
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  /// Seluruh transaksi (read-only)
  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);

  /// Daftar semua dompet termasuk yang sudah dihapus/arsip (read-only)
  List<Wallet> get allWallets => List.unmodifiable(_wallets);

  /// Daftar dompet yang masih aktif digunakan untuk transaksi (read-only)
  List<Wallet> get activeWallets =>
      List.unmodifiable(_wallets.where((w) => !w.isDeleted));

  /// Mengambil data dompet berdasarkan ID
  Wallet? getWalletById(String id) {
    try {
      return _wallets.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Wallet Operations ─────────────────────────────────────────────────────

  /// Membuat dompet baru dengan opsi saldo awal
  Wallet createWallet(String name, {double initialBalance = 0.0}) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Nama dompet tidak boleh kosong');
    }

    final id =
        'wallet_${DateTime.now().microsecondsSinceEpoch}_${_wallets.length + 1}';
    final newWallet = Wallet(
      id: id,
      name: trimmedName,
      createdAt: DateTime.now(),
    );
    _wallets.add(newWallet);

    if (initialBalance > 0) {
      addIncome(
        initialBalance,
        walletId: id,
        title: 'Saldo Awal $trimmedName',
      );
    } else {
      _persist();
      notifyListeners();
    }

    return newWallet;
  }

  /// Mengatur dompet awal dan uang bawaan saat pertama kali setup aplikasi.
  /// Hanya dompet yang diinput di awal yang menjadi dompet aktif.
  Wallet setupInitialWallet({
    required String walletName,
    required double initialBalance,
  }) {
    final trimmedName = walletName.trim();
    _wallets.clear();
    _transactions.clear();

    final targetWallet = Wallet(
      id: 'wallet_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmedName,
      createdAt: DateTime.now(),
    );
    _wallets.add(targetWallet);

    if (initialBalance > 0) {
      addIncome(
        initialBalance,
        walletId: targetWallet.id,
        title: 'Saldo Awal - $trimmedName',
      );
    } else {
      _persist();
      notifyListeners();
    }

    return targetWallet;
  }

  /// Soft delete dompet (transaksi lampau tetap ada, tetapi tidak muncul lagi di pilihan baru)
  void deleteWallet(String walletId) {
    final index = _wallets.indexWhere((w) => w.id == walletId);
    if (index != -1) {
      _wallets[index] = _wallets[index].copyWith(isDeleted: true);
      _persist();
      notifyListeners();
    }
  }

  // ── Balance ───────────────────────────────────────────────────────────────

  /// Menghitung saldo untuk dompet tertentu
  double getWalletBalance(String walletId) {
    double balance = 0.0;
    for (final t in _transactions) {
      if (t.walletId == walletId) {
        if (t.type == TransactionType.income) {
          balance += t.amount;
        } else if (t.type == TransactionType.expense) {
          balance -= t.amount;
        } else if (t.type == TransactionType.transfer) {
          balance -= t.amount; // Saldo keluar dari dompet asal
        }
      }
      if (t.type == TransactionType.transfer &&
          t.destinationWalletId == walletId) {
        balance += t.amount; // Saldo masuk ke dompet tujuan
      }
    }
    return balance;
  }

  /// Cek apakah saldo dompet kurang dari nominal pengeluaran/transfer
  bool isBalanceInsufficient(String walletId, double amount) {
    return getWalletBalance(walletId) < amount;
  }

  /// Menghitung total semua uang masuk (pemasukan riil)
  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Menghitung total semua uang keluar (pengeluaran riil)
  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Menghitung sisa total uang (pemasukan - pengeluaran)
  double get totalBalance => totalIncome - totalExpense;

  // ── Transaction Operations ────────────────────────────────────────────────

  /// Tambah uang (Pemasukan)
  void addIncome(
    double amount, {
    String? walletId,
    String? title,
    DateTime? date,
  }) {
    if (amount <= 0) return;
    final targetWalletId = walletId ??
        (activeWallets.isNotEmpty ? activeWallets.first.id : defaultWalletId);

    _add(
      amount: amount,
      title:
          (title == null || title.trim().isEmpty) ? 'Pemasukan' : title.trim(),
      type: TransactionType.income,
      walletId: targetWalletId,
      date: date,
    );
  }

  /// Kurang uang (Pengeluaran)
  void addExpense(
    double amount, {
    String? walletId,
    String? title,
    DateTime? date,
  }) {
    if (amount <= 0) return;
    final targetWalletId = walletId ??
        (activeWallets.isNotEmpty ? activeWallets.first.id : defaultWalletId);

    _add(
      amount: amount,
      title: (title == null || title.trim().isEmpty)
          ? 'Pengeluaran'
          : title.trim(),
      type: TransactionType.expense,
      walletId: targetWalletId,
      date: date,
    );
  }

  /// Pindah saldo antar dompet
  void transferBalance({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? title,
    DateTime? date,
  }) {
    if (amount <= 0) return;
    if (fromWalletId == toWalletId) return;

    final fromWallet = getWalletById(fromWalletId);
    final toWallet = getWalletById(toWalletId);
    final defaultTitle =
        'Transfer: ${fromWallet?.name ?? fromWalletId} -> ${toWallet?.name ?? toWalletId}';

    _add(
      amount: amount,
      title:
          (title == null || title.trim().isEmpty) ? defaultTitle : title.trim(),
      type: TransactionType.transfer,
      walletId: fromWalletId,
      destinationWalletId: toWalletId,
      date: date,
    );
  }

  static int _idCounter = 0;

  void _add({
    required double amount,
    required String title,
    required TransactionType type,
    required String walletId,
    String? destinationWalletId,
    DateTime? date,
  }) {
    _idCounter++;
    final newTransaction = TransactionRecord(
      id: '${DateTime.now().microsecondsSinceEpoch}_$_idCounter',
      title: title,
      amount: amount,
      type: type,
      walletId: walletId,
      destinationWalletId: destinationWalletId,
      date: date ?? DateTime.now(),
    );

    // Tambahkan di awal agar transaksi terbaru selalu berada di paling atas
    _transactions.insert(0, newTransaction);
    _persist();
    notifyListeners();
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Mengambil riwayat transaksi untuk dompet tertentu
  List<TransactionRecord> getTransactionsByWallet(String walletId) {
    return _transactions
        .where((t) =>
            t.walletId == walletId ||
            (t.type == TransactionType.transfer &&
                t.destinationWalletId == walletId))
        .toList();
  }

  /// Mengambil transaksi berdasarkan filter waktu (3 hari, 7 hari, 30 hari, atau semua)
  List<TransactionRecord> getFilteredTransactions(
    TimeFilter filter, {
    DateTime? customNow,
  }) {
    if (filter == TimeFilter.all) {
      return transactions;
    }

    final now = customNow ?? DateTime.now();
    final int days;
    switch (filter) {
      case TimeFilter.last3Days:
        days = 3;
        break;
      case TimeFilter.last7Days:
        days = 7;
        break;
      case TimeFilter.last30Days:
        days = 30;
        break;
      case TimeFilter.all:
        return transactions;
    }

    final startOfCurrentDay = DateTime(now.year, now.month, now.day);
    final cutoff = startOfCurrentDay.subtract(Duration(days: days - 1));

    return _transactions.where((t) {
      return t.date.isAfter(cutoff) || t.date.isAtSameMomentAs(cutoff);
    }).toList();
  }

  /// Mengambil transaksi berdasarkan bulan dan tahun tertentu
  List<TransactionRecord> getTransactionsByMonth(MonthYear monthYear) {
    return _transactions.where((t) {
      return t.date.year == monthYear.year && t.date.month == monthYear.month;
    }).toList();
  }

  /// Mengambil daftar bulan yang tersedia
  List<MonthYear> getAvailableMonths({DateTime? customNow}) {
    final now = customNow ?? DateTime.now();
    final currentMonth = MonthYear(now.year, now.month);

    DateTime earliestDate = now;
    for (final t in _transactions) {
      if (t.date.isBefore(earliestDate)) {
        earliestDate = t.date;
      }
    }

    var earliestMonth = MonthYear(earliestDate.year, earliestDate.month);
    if (earliestMonth == currentMonth) {
      earliestMonth = currentMonth.previous();
    }
    final List<MonthYear> months = [];

    var ptr = currentMonth;
    while (true) {
      months.add(ptr);
      if (ptr.year == earliestMonth.year && ptr.month == earliestMonth.month) {
        break;
      }
      if (ptr.year < earliestMonth.year ||
          (ptr.year == earliestMonth.year && ptr.month < earliestMonth.month)) {
        break;
      }
      ptr = ptr.previous();
    }

    return months;
  }

  /// Hapus transaksi berdasarkan ID
  void deleteTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    _persist();
    notifyListeners();
  }

  /// Kosongkan semua data transaksi
  void clearAll({bool resetWallets = false}) {
    _transactions.clear();
    if (resetWallets) {
      _wallets.clear();
      _initializeDefaultWallets();
    }
    _persist();
    notifyListeners();
  }
}
