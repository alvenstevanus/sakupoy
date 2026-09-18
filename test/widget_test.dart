import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakupoy/main.dart';
import 'package:sakupoy/models/transaction.dart';
import 'package:sakupoy/models/wallet.dart';
import 'package:sakupoy/services/transaction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Alur UX Tambah, Kurang Uang, dan Filter Dropdown Waktu & Bulan',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Render App
      await tester.pumpWidget(const SakuPoyApp());

      // 2. Verifikasi Saldo awal Rp 0
      expect(find.text('TOTAL SALDO'), findsOneWidget);
      expect(find.text('Rp 0'), findsWidgets);

      // 3. Tap tombol Tambah Uang via tombol center action (+) di bottom bar
      final centerBtn = find.byKey(const Key('button_center_action'));
      expect(centerBtn, findsOneWidget);
      await tester.tap(centerBtn);
      await tester.pumpAndSettle();

      final tambahButton = find.byKey(const Key('button_add_income'));
      expect(tambahButton, findsOneWidget);
      await tester.tap(tambahButton);
      await tester.pumpAndSettle(); // Tunggu modal sheet muncul

      // 4. Masukkan nominal 50000 dan simpan
      final nominalField = find.widgetWithText(TextFormField, 'Nominal (Rp)');
      expect(nominalField, findsOneWidget);
      await tester.enterText(nominalField, '50000');

      final simpanPemasukanBtn = find.text('Simpan Pemasukan');
      await tester.tap(simpanPemasukanBtn);
      await tester.pumpAndSettle();

      // 5. Verifikasi Total Saldo berubah jadi Rp 50.000
      expect(find.text('Rp 50.000'), findsWidgets);

      // 6. Tap tombol Kurang Uang via tombol center action (+)
      await tester.tap(centerBtn);
      await tester.pumpAndSettle();

      final kurangButton = find.byKey(const Key('button_add_expense'));
      expect(kurangButton, findsOneWidget);
      await tester.tap(kurangButton);
      await tester.pumpAndSettle();

      // 7. Masukkan nominal 20000 dan simpan
      final expenseNominalField = find.widgetWithText(
        TextFormField,
        'Nominal (Rp)',
      );
      await tester.enterText(expenseNominalField, '20000');

      final simpanPengeluaranBtn = find.text('Simpan Pengeluaran');
      await tester.tap(simpanPengeluaranBtn);
      await tester.pumpAndSettle();

      // 8. Verifikasi Total Saldo menjadi 50000 - 20000 = Rp 30.000
      expect(find.text('Rp 30.000'), findsWidgets);

      // Pindah ke Tab Riwayat
      await tester.tap(find.byKey(const Key('tab_history')));
      await tester.pumpAndSettle();

      // 9. Verifikasi Dropdown Filter tersedia
      final dropdownFinder = find.byKey(const Key('dropdown_filter'));
      expect(dropdownFinder, findsOneWidget);

      final now = DateTime.now();
      final currentMonth = MonthYear(now.year, now.month);
      final prevMonth = currentMonth.previous();

      // 10. Buka Dropdown dan pilih Bulan Ini (contoh: September 2026)
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Cari item dropdown untuk bulan ini (ada item di dalam dropdown menu popup)
      final currentMonthItem = find.text(currentMonth.label).last;
      await tester.tap(currentMonthItem);
      await tester.pumpAndSettle();

      expect(find.text('2 transaksi (${currentMonth.label})'), findsOneWidget);

      // 11. Buka Dropdown dan pilih Bulan Lalu (contoh: Agustus 2026)
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      final prevMonthItem = find.text(prevMonth.label).last;
      await tester.tap(prevMonthItem);
      await tester.pumpAndSettle();

      expect(
        find.text('Tidak ada transaksi pada ${prevMonth.label}'),
        findsOneWidget,
      );

      // 12. Kembali ke Semua Transaksi lewat tombol reset
      final showAllBtn = find.text('Tampilkan Semua Transaksi');
      await tester.ensureVisible(showAllBtn);
      await tester.tap(showAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('2 transaksi (Semua Transaksi)'), findsOneWidget);
    },
  );

  testWidgets('Alur UI Tambah Dompet Baru dan Transfer Antar Dompet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SakuPoyApp());

    // 1. Verifikasi bagian Dompet Saya tampil
    expect(find.text('Dompet Saya'), findsOneWidget);
    expect(find.text('Tunai / Cash'), findsOneWidget);
    expect(find.text('BRImo'), findsOneWidget);
    expect(find.text('DANA'), findsOneWidget);

    // 2. Buka dialog Tambah Dompet
    final addWalletBtn = find.byKey(const Key('button_add_wallet'));
    expect(addWalletBtn, findsOneWidget);
    await tester.tap(addWalletBtn);
    await tester.pumpAndSettle();

    expect(find.text('Tambah Jenis Dompet'), findsOneWidget);

    // 3. Masukkan Saldo Awal Rp 50.000 dan simpan
    final balanceField = find.widgetWithText(
      TextFormField,
      'Saldo Awal (Opsional)',
    );
    await tester.enterText(balanceField, '50000');

    final simpanDompetBtn = find.text('Simpan Dompet');
    await tester.tap(simpanDompetBtn);
    await tester.pumpAndSettle();

    // 4. Verifikasi Total Saldo bertambah menjadi Rp 50.000
    expect(find.text('TOTAL SALDO'), findsOneWidget);
    expect(find.text('Rp 50.000'), findsWidgets);

    // 5. Buka sheet Transfer Saldo
    final transferBtn = find.byKey(const Key('button_transfer_balance'));
    expect(transferBtn, findsOneWidget);
    await tester.tap(transferBtn);
    await tester.pumpAndSettle();

    expect(find.text('Pindah Saldo (Transfer)'), findsOneWidget);

    // 6. Masukkan nominal transfer Rp 20.000 dan simpan
    final transferNominalField = find.widgetWithText(
      TextFormField,
      'Nominal Pindah (Rp)',
    );
    await tester.enterText(transferNominalField, '20000');

    final submitTransferBtn = find.text('Pindahkan Saldo');
    await tester.tap(submitTransferBtn);
    await tester.pumpAndSettle();

    // Muncul dialog peringatan saldo tidak mencukupi, tekan Teruskan
    expect(find.text('Saldo Tidak Mencukupi'), findsOneWidget);
    await tester.tap(find.text('Teruskan'));
    await tester.pumpAndSettle();

    // 7. Pindah ke Tab Riwayat untuk melihat mutasi transfer
    await tester.tap(find.byKey(const Key('tab_history')));
    await tester.pumpAndSettle();

    // Verifikasi transaksi transfer tercatat
    expect(find.byIcon(Icons.swap_horiz), findsWidgets);
  });

  testWidgets(
    'Alur Welcome Page: Input Uang Bawaan dan Mulai Aplikasi dari Awal',
    (WidgetTester tester) async {
      // 1. Jalankan aplikasi dari kondisi fresh install (hasSeenWelcome = false)
      await tester.pumpWidget(const SakuPoyApp(hasSeenWelcome: false));

      // Verifikasi berada di WelcomePage
      expect(find.text('Catat Transaksi'), findsOneWidget);

      // 2. Tekan tombol Mulai
      final startButton = find.byKey(const Key('button_start_app'));
      expect(startButton, findsOneWidget);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // 3. Verifikasi sheet Atur Dompet & Saldo Awal muncul
      expect(find.text('Atur Dompet & Saldo Awal'), findsOneWidget);

      // 4. Masukkan uang bawaan (saldo awal) Rp 500.000
      final initialBalanceField = find.byKey(
        const Key('input_initial_balance'),
      );
      expect(initialBalanceField, findsOneWidget);
      await tester.enterText(initialBalanceField, '500000');

      // 5. Tekan tombol Mulai Gunakan SakuPoy
      final submitInitialBtn = find.byKey(
        const Key('button_submit_initial_wallet'),
      );
      expect(submitInitialBtn, findsOneWidget);
      await tester.tap(submitInitialBtn);
      await tester.pumpAndSettle();

      // Verifikasi bahwa pointer/mouse hover di area navigasi tidak memicu Scaffold.geometryOf exception
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(400, 1150));
      await tester.pump();

      // 6. Verifikasi berhasil masuk ke FinanceHomePage dan Total Saldo Rp 500.000
      expect(find.text('TOTAL SALDO'), findsOneWidget);
      expect(find.text('Rp 500.000'), findsWidgets);
      expect(find.text('Dompet Saya'), findsOneWidget);
      expect(find.text('Tunai / Cash'), findsWidgets);
      expect(find.text('BRImo'), findsNothing);
      expect(find.text('DANA'), findsNothing);

      // 7. Pindah ke Tab Profil dan tekan Mulai Aplikasi dari Awal
      final profileTab = find.byKey(const Key('tab_profile'));
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      final restartAppBtn = find.byKey(const Key('button_restart_app_profile'));
      expect(restartAppBtn, findsOneWidget);
      await tester.tap(restartAppBtn);
      await tester.pumpAndSettle();

      // Muncul dialog konfirmasi
      expect(find.text('Mulai dari Awal?'), findsOneWidget);
      final confirmRestartBtn = find.widgetWithText(
        FilledButton,
        'Mulai dari Awal',
      );
      await tester.tap(confirmRestartBtn);
      await tester.pumpAndSettle();

      // 8. Verifikasi kembali ke Welcome Page (reset total)
      expect(find.text('Catat Transaksi'), findsOneWidget);
    },
  );

  testWidgets('Konfirmasi modal saat menghapus transaksi dan dompet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const SakuPoyApp());

    // 1. Tambah transaksi pemasukan via center action button (+)
    final centerBtn = find.byKey(const Key('button_center_action'));
    await tester.tap(centerBtn);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('button_add_income')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nominal (Rp)'),
      '75000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Catatan / Keterangan (opsional)'),
      'Gaji Tambahan',
    );
    await tester.tap(find.text('Simpan Pemasukan'));
    await tester.pumpAndSettle();

    // 2. Pindah ke Tab Riwayat untuk menguji hapus transaksi
    await tester.tap(find.byKey(const Key('tab_history')));
    await tester.pumpAndSettle();

    expect(find.text('Gaji Tambahan'), findsOneWidget);

    // Tekan ikon hapus pada transaksi
    final deleteTxBtn = find.byIcon(Icons.delete_outline);
    await tester.tap(deleteTxBtn.first);
    await tester.pumpAndSettle();

    // Verifikasi muncul modal konfirmasi dengan teks pola "Yakin ingin menghapus {item} ini?"
    expect(find.text('Hapus Transaksi'), findsOneWidget);
    expect(
      find.text('Yakin ingin menghapus transaksi "Gaji Tambahan" ini?'),
      findsOneWidget,
    );

    // Tekan Batal, transaksi tidak terhapus
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Gaji Tambahan'), findsOneWidget);

    // Tekan Hapus lagi dan konfirmasi Hapus
    await tester.tap(deleteTxBtn.first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();

    // Transaksi berhasil terhapus
    expect(find.text('Gaji Tambahan'), findsNothing);

    // 3. Kembali ke Tab Beranda untuk menguji hapus dompet dengan konfirmasi
    await tester.tap(find.byKey(const Key('tab_home')));
    await tester.pumpAndSettle();

    // Buka menu titik tiga pada salah satu dompet
    final moreBtn = find.byIcon(Icons.more_vert).first;
    await tester.tap(moreBtn);
    await tester.pumpAndSettle();

    // Pilih Hapus Dompet
    await tester.tap(find.text('Hapus Dompet'));
    await tester.pumpAndSettle();

    // Verifikasi dialog modal konfirmasi hapus dompet
    expect(find.text('Hapus Dompet'), findsOneWidget);
    expect(find.textContaining('Yakin ingin menghapus dompet'), findsOneWidget);

    // Tekan Batal
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    // Menu tertutup dan dompet tetap ada
    expect(find.text('Hapus Dompet'), findsNothing);
  });

  testWidgets(
    'Alur Navigasi Bottom Bar: Pindah ke Tab Profil dan Kembali ke Beranda',
    (WidgetTester tester) async {
      await tester.pumpWidget(const SakuPoyApp());

      // Berada di Tab Beranda secara default
      expect(find.text('TOTAL SALDO'), findsOneWidget);
      expect(find.text('Dompet Saya'), findsOneWidget);

      // 1. Pindah ke Tab Profil
      final profileTab = find.byKey(const Key('tab_profile'));
      expect(profileTab, findsOneWidget);
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      // Verifikasi berada di halaman Profil
      expect(find.text('Pengguna SakuPoy'), findsOneWidget);
      expect(find.text('Pengaturan Aplikasi'), findsOneWidget);
      expect(find.text('Dompet Aktif'), findsOneWidget);

      // 2. Kembali ke Tab Beranda
      final homeTab = find.byKey(const Key('tab_home'));
      expect(homeTab, findsOneWidget);
      await tester.tap(homeTab);
      await tester.pumpAndSettle();

      // Verifikasi kembali di Beranda
      expect(find.text('TOTAL SALDO'), findsOneWidget);
      expect(find.text('Dompet Saya'), findsOneWidget);
    },
  );

  testWidgets(
    'SnackBar toast muncul saat aksi transfer tidak memenuhi syarat',
    (WidgetTester tester) async {
      // Inisialisasi dengan 1 dompet aktif
      final service = TransactionService(
        initialWallets: [
          Wallet(id: 'w1', name: 'Kas Utama', createdAt: DateTime.now()),
        ],
      );
      await tester.pumpWidget(SakuPoyApp(service: service));

      // Memicu SnackBar dengan menekan Pindah Saldo saat dompet < 2
      final transferBtn = find.byKey(const Key('button_transfer_balance'));
      expect(transferBtn, findsOneWidget);
      await tester.tap(transferBtn);
      await tester.pump(); // memunculkan snackbar

      expect(
        find.text('Dibutuhkan minimal 2 dompet aktif untuk memindahkan saldo.'),
        findsOneWidget,
      );
    },
  );
}
