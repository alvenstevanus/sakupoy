import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

class TransactionService extends ChangeNotifier {
  final List<TransactionRecord> _transactions = [];

  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);

  /// Menghitung total semua uang masuk (pemasukan)
  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Menghitung total semua uang keluar (pengeluaran)
  double get totalExpense {
    return _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Menghitung sisa total uang (pemasukan - pengeluaran)
  double get totalBalance => totalIncome - totalExpense;

  /// Tambah uang (Pemasukan)
  void addIncome(double amount, {String? title, DateTime? date}) {
    if (amount <= 0) return;
    _add(
      amount: amount,
      title: (title == null || title.trim().isEmpty) ? 'Pemasukan' : title.trim(),
      type: TransactionType.income,
      date: date,
    );
  }

  /// Kurang uang (Pengeluaran)
  void addExpense(double amount, {String? title, DateTime? date}) {
    if (amount <= 0) return;
    _add(
      amount: amount,
      title: (title == null || title.trim().isEmpty) ? 'Pengeluaran' : title.trim(),
      type: TransactionType.expense,
      date: date,
    );
  }

  static int _idCounter = 0;

  void _add({
    required double amount,
    required String title,
    required TransactionType type,
    DateTime? date,
  }) {
    _idCounter++;
    final newTransaction = TransactionRecord(
      id: '${DateTime.now().microsecondsSinceEpoch}_$_idCounter',
      title: title,
      amount: amount,
      type: type,
      date: date ?? DateTime.now(),
    );

    // Tambahkan di awal agar transaksi terbaru selalu berada di paling atas
    _transactions.insert(0, newTransaction);
    notifyListeners();
  }

  /// Mengambil transaksi berdasarkan filter waktu (3 hari, 7 hari, 30 hari, atau semua)
  List<TransactionRecord> getFilteredTransactions(TimeFilter filter, {DateTime? customNow}) {
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

    // Cutoff waktu dihitung dari awal hari (00:00:00) X hari yang lalu
    final startOfCurrentDay = DateTime(now.year, now.month, now.day);
    final cutoff = startOfCurrentDay.subtract(Duration(days: days - 1));

    return _transactions.where((t) {
      return t.date.isAfter(cutoff) || t.date.isAtSameMomentAs(cutoff);
    }).toList();
  }

  /// Mengambil transaksi berdasarkan bulan dan tahun tertentu (contoh: September 2026, Agustus 2026)
  List<TransactionRecord> getTransactionsByMonth(MonthYear monthYear) {
    return _transactions.where((t) {
      return t.date.year == monthYear.year && t.date.month == monthYear.month;
    }).toList();
  }

  /// Mengambil daftar bulan yang tersedia, mulai dari bulan saat ini mundur sampai bulan transaksi pertama.
  /// Contoh: jika transaksi pertama di bulan Juni 2026 dan bulan ini September 2026,
  /// maka bulan paling lama yang bisa diakses adalah Juni 2026.
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
    notifyListeners();
  }

  /// Kosongkan semua data transaksi
  void clearAll() {
    _transactions.clear();
    notifyListeners();
  }
}
