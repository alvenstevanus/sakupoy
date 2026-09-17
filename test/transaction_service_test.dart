import 'package:flutter_test/flutter_test.dart';
import 'package:sakupoy/models/transaction.dart';
import 'package:sakupoy/services/transaction_service.dart';

void main() {
  group('TransactionService Tests', () {
    late TransactionService service;

    setUp(() {
      service = TransactionService();
    });

    test('Saldo awal harus 0', () {
      expect(service.totalBalance, 0.0);
      expect(service.totalIncome, 0.0);
      expect(service.totalExpense, 0.0);
      expect(service.transactions, isEmpty);
    });

    test('Fungsi Tambah Uang (Income) menambah total saldo dengan benar', () {
      service.addIncome(50000, title: 'Gaji');

      expect(service.totalIncome, 50000.0);
      expect(service.totalExpense, 0.0);
      expect(service.totalBalance, 50000.0);
      expect(service.transactions.length, 1);
      expect(service.transactions.first.type, TransactionType.income);
      expect(service.transactions.first.title, 'Gaji');
    });

    test(
      'Fungsi Kurang Uang (Expense) mengurangi total saldo dengan benar',
      () {
        service.addExpense(20000, title: 'Makan Siang');

        expect(service.totalIncome, 0.0);
        expect(service.totalExpense, 20000.0);
        expect(service.totalBalance, -20000.0);
        expect(service.transactions.length, 1);
        expect(service.transactions.first.type, TransactionType.expense);
      },
    );

    test(
      'Kombinasi Tambah dan Kurang Uang menghasilkan total uang yang akurat',
      () {
        service.addIncome(100000, title: 'Dapat Uang');
        service.addExpense(35000, title: 'Beli Makan');
        service.addIncome(50000, title: 'Bonus');
        service.addExpense(15000, title: 'Bensin');

        expect(service.totalIncome, 150000.0);
        expect(service.totalExpense, 50000.0);
        expect(service.totalBalance, 100000.0);
        expect(service.transactions.length, 4);
      },
    );

    test('Hapus transaksi memperbarui total saldo secara otomatis', () {
      service.addIncome(100000, title: 'Uang 1');
      service.addExpense(30000, title: 'Beli Barang');
      final expenseId = service.transactions.first.id;

      expect(service.totalBalance, 70000.0);

      service.deleteTransaction(expenseId);
      expect(service.totalBalance, 100000.0);
      expect(service.totalExpense, 0.0);
      expect(service.transactions.length, 1);
    });

    test('Nominal <= 0 diabaikan untuk menjaga integritas data', () {
      service.addIncome(0);
      service.addExpense(-1000);

      expect(service.transactions, isEmpty);
      expect(service.totalBalance, 0.0);
    });

    test('Filter waktu transaksi (3 hari, 7 hari, 1 bulan, dan semua)', () {
      final now = DateTime(2026, 9, 18, 12, 0);

      // 1. Hari ini (0 hari lalu)
      service.addIncome(10000, title: 'Hari Ini', date: now);
      // 2. 2 hari lalu
      service.addExpense(
        5000,
        title: '2 Hari Lalu',
        date: now.subtract(const Duration(days: 2)),
      );
      // 3. 5 hari lalu
      service.addIncome(
        20000,
        title: '5 Hari Lalu',
        date: now.subtract(const Duration(days: 5)),
      );
      // 4. 20 hari lalu
      service.addExpense(
        15000,
        title: '20 Hari Lalu',
        date: now.subtract(const Duration(days: 20)),
      );
      // 5. 45 hari lalu
      service.addIncome(
        50000,
        title: '45 Hari Lalu',
        date: now.subtract(const Duration(days: 45)),
      );

      // Filter 3 Hari Terakhir: Hari ini + 2 hari lalu = 2
      final last3Days = service.getFilteredTransactions(
        TimeFilter.last3Days,
        customNow: now,
      );
      expect(last3Days.length, 2);
      expect(
        last3Days.map((t) => t.title),
        containsAll(['Hari Ini', '2 Hari Lalu']),
      );

      // Filter 7 Hari Terakhir: Hari ini + 2 hari lalu + 5 hari lalu = 3
      final last7Days = service.getFilteredTransactions(
        TimeFilter.last7Days,
        customNow: now,
      );
      expect(last7Days.length, 3);
      expect(
        last7Days.map((t) => t.title),
        containsAll(['Hari Ini', '2 Hari Lalu', '5 Hari Lalu']),
      );

      // Filter 1 Bulan (30 Hari) Terakhir: 4 transaksi (kecuali 45 hari lalu)
      final last30Days = service.getFilteredTransactions(
        TimeFilter.last30Days,
        customNow: now,
      );
      expect(last30Days.length, 4);

      // Filter Semua: 5 transaksi
      final all = service.getFilteredTransactions(
        TimeFilter.all,
        customNow: now,
      );
      expect(all.length, 5);
    });

    test('getAvailableMonths menyediakan minimal bulan ini dan bulan sebelumnya', () {
      final now = DateTime(2026, 9, 18);
      final months = service.getAvailableMonths(customNow: now);
      expect(months.length, greaterThanOrEqualTo(2));
      expect(months.first, const MonthYear(2026, 9));
      expect(months[1], const MonthYear(2026, 8));
    });

    test('getAvailableMonths mencakup hingga bulan transaksi paling awal', () {
      final now = DateTime(2026, 9, 18);
      service.addIncome(10000, date: DateTime(2026, 6, 1));
      final months = service.getAvailableMonths(customNow: now);
      expect(months.length, 4); // September, Agustus, Juli, Juni
      expect(months.first, const MonthYear(2026, 9));
      expect(months.last, const MonthYear(2026, 6));
    });

    test('getTransactionsByMonth memfilter transaksi berdasarkan bulan & tahun', () {
      service.addIncome(10000, title: 'Juni', date: DateTime(2026, 6, 15));
      service.addIncome(20000, title: 'Juli', date: DateTime(2026, 7, 10));

      final juneList = service.getTransactionsByMonth(const MonthYear(2026, 6));
      expect(juneList.length, 1);
      expect(juneList.first.title, 'Juni');

      final augustList = service.getTransactionsByMonth(const MonthYear(2026, 8));
      expect(augustList, isEmpty);
    });
  });
}
