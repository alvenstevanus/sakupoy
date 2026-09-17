import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakupoy/main.dart';
import 'package:sakupoy/models/transaction.dart';

void main() {
  testWidgets('Alur UX Tambah, Kurang Uang, dan Filter Dropdown Waktu & Bulan', (
    WidgetTester tester,
  ) async {
    // 1. Render App
    await tester.pumpWidget(const SakuPoyApp());

    // 2. Verifikasi Saldo awal Rp 0
    expect(find.text('TOTAL SALDO'), findsOneWidget);
    expect(find.text('Rp 0'), findsWidgets);

    // 3. Tap tombol Tambah Uang
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

    // 6. Tap tombol Kurang Uang
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
    expect(find.text('Rp 30.000'), findsOneWidget);

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

    expect(find.text('Tidak ada transaksi pada ${prevMonth.label}'), findsOneWidget);

    // 12. Kembali ke Semua Transaksi lewat tombol reset
    await tester.tap(find.text('Tampilkan Semua Transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('2 transaksi (Semua Transaksi)'), findsOneWidget);
  });
}
