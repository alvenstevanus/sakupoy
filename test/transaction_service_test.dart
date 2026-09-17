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

    group('Multi-Wallet / Sumber Dana Tests', () {
      test('Inisialisasi awal menyediakan dompet bawaan (Cash, BRImo, DANA)', () {
        expect(service.activeWallets.length, 3);
        final walletNames = service.activeWallets.map((w) => w.name).toList();
        expect(walletNames, containsAll(['Tunai / Cash', 'BRImo', 'DANA']));
      });

      test('createWallet tanpa saldo awal menghasilkan saldo Rp 0', () {
        final wallet = service.createWallet('Bank BCA');
        expect(wallet.name, 'Bank BCA');
        expect(service.getWalletBalance(wallet.id), 0.0);
        expect(service.activeWallets.any((w) => w.id == wallet.id), isTrue);
      });

      test('createWallet dengan saldo awal otomatis mencatat transaksi pemasukan awal', () {
        final wallet = service.createWallet('Bank Mandiri', initialBalance: 150000);
        expect(service.getWalletBalance(wallet.id), 150000.0);
        expect(service.totalBalance, 150000.0);
        expect(service.totalIncome, 150000.0);
        expect(service.transactions.first.walletId, wallet.id);
        expect(service.transactions.first.title, contains('Saldo Awal'));
      });

      test('Pemasukan dan Pengeluaran tercatat akurat per dompet', () {
        final cash = service.activeWallets.firstWhere((w) => w.name.contains('Cash'));
        final brimo = service.activeWallets.firstWhere((w) => w.name == 'BRImo');

        service.addIncome(200000, walletId: cash.id, title: 'Tarik Tunai Teman');
        service.addIncome(500000, walletId: brimo.id, title: 'Gaji Pokok');

        expect(service.getWalletBalance(cash.id), 200000.0);
        expect(service.getWalletBalance(brimo.id), 500000.0);
        expect(service.totalBalance, 700000.0);

        service.addExpense(50000, walletId: cash.id, title: 'Beli Makan');
        expect(service.getWalletBalance(cash.id), 150000.0);
        expect(service.getWalletBalance(brimo.id), 500000.0);
        expect(service.totalBalance, 650000.0);
      });

      test('Transfer antar dompet memindahkan saldo tanpa mengubah Total Saldo Keseluruhan', () {
        final cash = service.activeWallets.firstWhere((w) => w.name.contains('Cash'));
        final brimo = service.activeWallets.firstWhere((w) => w.name == 'BRImo');

        // Isi saldo awal di BRImo sebesar 300.000
        service.addIncome(300000, walletId: brimo.id, title: 'Transfer Masuk');

        expect(service.getWalletBalance(brimo.id), 300000.0);
        expect(service.getWalletBalance(cash.id), 0.0);
        expect(service.totalBalance, 300000.0);

        // Tarik tunai / transfer dari BRImo ke Cash sebesar 100.000
        service.transferBalance(
          fromWalletId: brimo.id,
          toWalletId: cash.id,
          amount: 100000,
          title: 'Tarik Tunai ATM',
        );

        // Verifikasi saldo masing-masing dompet
        expect(service.getWalletBalance(brimo.id), 200000.0);
        expect(service.getWalletBalance(cash.id), 100000.0);

        // Total Saldo, Total Income, dan Total Expense tetap utuh (transfer bukan belanja/gaji)
        expect(service.totalBalance, 300000.0);
        expect(service.totalIncome, 300000.0);
        expect(service.totalExpense, 0.0);
      });

      test('Validasi isBalanceInsufficient mendeteksi jika saldo tidak mencukupi', () {
        final cash = service.activeWallets.firstWhere((w) => w.name.contains('Cash'));
        service.addIncome(50000, walletId: cash.id);

        expect(service.isBalanceInsufficient(cash.id, 30000), isFalse);
        expect(service.isBalanceInsufficient(cash.id, 50000), isFalse);
        expect(service.isBalanceInsufficient(cash.id, 60000), isTrue);
      });

      test('Saldo dompet dapat bernilai minus jika pengeluaran melebihi saldo', () {
        final dana = service.activeWallets.firstWhere((w) => w.name == 'DANA');
        service.addIncome(20000, walletId: dana.id);
        service.addExpense(50000, walletId: dana.id, title: 'Langganan Musik');

        expect(service.getWalletBalance(dana.id), -30000.0);
        expect(service.totalBalance, -30000.0);
      });

      test('Soft delete dompet mempertahankan riwayat transaksi namun hilang dari activeWallets', () {
        final wallet = service.createWallet('Dompet Cadangan', initialBalance: 100000);
        final walletId = wallet.id;

        expect(service.activeWallets.any((w) => w.id == walletId), isTrue);

        service.deleteWallet(walletId);

        // Hilang dari activeWallets
        expect(service.activeWallets.any((w) => w.id == walletId), isFalse);
        // Tetap ada di allWallets
        expect(service.allWallets.any((w) => w.id == walletId), isTrue);
        expect(service.getWalletById(walletId)?.isDeleted, isTrue);

        // Riwayat transaksi tetap ada dan saldo tetap terhitung
        expect(service.getTransactionsByWallet(walletId).length, 1);
        expect(service.totalBalance, 100000.0);
      });

      test('setupInitialWallet hanya menyisakan dompet yang diinput di awal sebagai dompet aktif', () {
        // Awalnya ada 3 dompet default
        expect(service.activeWallets.length, 3);

        // User setup dompet awal (misal: 'BCA' dengan saldo Rp 1.500.000)
        final initialWallet = service.setupInitialWallet(
          walletName: 'BCA',
          initialBalance: 1500000,
        );

        // Hanya dompet yang diinput di awal yang aktif
        expect(service.activeWallets.length, 1);
        expect(service.activeWallets.first.id, initialWallet.id);
        expect(service.activeWallets.first.name, 'BCA');
        expect(service.getWalletBalance(initialWallet.id), 1500000.0);
        expect(service.totalBalance, 1500000.0);

        // Dompet bawaan lain (Cash, BRImo, DANA) tidak ada lagi
        expect(service.activeWallets.any((w) => w.name == 'Tunai / Cash'), isFalse);
        expect(service.activeWallets.any((w) => w.name == 'BRImo'), isFalse);
        expect(service.activeWallets.any((w) => w.name == 'DANA'), isFalse);
      });

      test('setupInitialWallet dengan preset bawaan hanya mengaktifkan preset tersebut', () {
        // User memilih preset bawaan 'BRImo' dengan saldo Rp 500.000
        final initialWallet = service.setupInitialWallet(
          walletName: 'BRImo',
          initialBalance: 500000,
        );

        // Hanya BRImo yang aktif
        expect(service.activeWallets.length, 1);
        expect(service.activeWallets.first.id, initialWallet.id);
        expect(service.activeWallets.first.name, 'BRImo');
        expect(service.getWalletBalance(initialWallet.id), 500000.0);
        expect(service.totalBalance, 500000.0);

        // Preset bawaan lain (Cash & DANA) tidak ikut aktif
        expect(service.activeWallets.any((w) => w.name == 'Tunai / Cash'), isFalse);
        expect(service.activeWallets.any((w) => w.name == 'DANA'), isFalse);
      });
    });
  });
}
