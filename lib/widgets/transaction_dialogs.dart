import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../models/wallet.dart';
import '../screens/welcome_page.dart';
import '../services/preference_service.dart';
import '../services/transaction_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

// ── Dialog Tambah Dompet ───────────────────────────────────────────────────

void showAddWalletDialog(BuildContext context, TransactionService service) {
  String selectedPreset = Wallet.presetWallets.first;
  bool isCustom = false;
  final customNameController = TextEditingController();
  final balanceController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              'Tambah Jenis Dompet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Pilih Jenis / Template Dompet:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: isCustom ? 'Lainnya' : selectedPreset,
                      key: ValueKey(
                        'preset_${isCustom ? 'Lainnya' : selectedPreset}',
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        ...Wallet.presetWallets.map(
                          (p) => DropdownMenuItem(value: p, child: Text(p)),
                        ),
                        const DropdownMenuItem(
                          value: 'Lainnya',
                          child: Text('Lainnya (Tulis Sendiri)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            if (value == 'Lainnya') {
                              isCustom = true;
                            } else {
                              isCustom = false;
                              selectedPreset = value;
                            }
                          });
                        }
                      },
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: customNameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Nama Dompet',
                          hintText: 'Contoh: Tabungan Liburan, Seabank',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama dompet wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Saldo Awal (Opsional)',
                        hintText: '0',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  if (isCustom &&
                      !(formKey.currentState?.validate() ?? false)) {
                    return;
                  }
                  final walletName = isCustom
                      ? customNameController.text.trim()
                      : selectedPreset;
                  final rawBalance = balanceController.text.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );
                  final balance = double.tryParse(rawBalance) ?? 0.0;

                  service.createWallet(walletName, initialBalance: balance);
                  Navigator.pop(dialogCtx);
                },
                child: const Text('Simpan Dompet'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ── Sheet Transfer Antar Dompet ─────────────────────────────────────────────

void showTransferSheet(BuildContext context, TransactionService service) {
  if (service.activeWallets.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Dibutuhkan minimal 2 dompet aktif untuk memindahkan saldo.',
        ),
      ),
    );
    return;
  }

  String fromWalletId = service.activeWallets.first.id;
  String toWalletId = service.activeWallets[1].id;
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final fromWallet = service.getWalletById(fromWalletId);
          final fromBalance = service.getWalletBalance(fromWalletId);

          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.blue,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Pindah Saldo (Transfer)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('from_$fromWalletId'),
                    initialValue: fromWalletId,
                    decoration: const InputDecoration(
                      labelText: 'Dari Dompet (Asal)',
                      border: OutlineInputBorder(),
                    ),
                    items: service.activeWallets.map((w) {
                      final bal = service.getWalletBalance(w.id);
                      return DropdownMenuItem(
                        value: w.id,
                        child: Text(
                          '${w.name} (Sisa: ${CurrencyFormatter.format(bal)})',
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() {
                          fromWalletId = val;
                          if (fromWalletId == toWalletId) {
                            toWalletId = service.activeWallets
                                .firstWhere((w) => w.id != val)
                                .id;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('to_$toWalletId'),
                    initialValue: toWalletId,
                    decoration: const InputDecoration(
                      labelText: 'Ke Dompet (Tujuan)',
                      border: OutlineInputBorder(),
                    ),
                    items: service.activeWallets
                        .where((w) => w.id != fromWalletId)
                        .map((w) {
                          final bal = service.getWalletBalance(w.id);
                          return DropdownMenuItem(
                            value: w.id,
                            child: Text(
                              '${w.name} (Sisa: ${CurrencyFormatter.format(bal)})',
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() {
                          toWalletId = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Nominal Pindah (Rp)',
                      hintText: 'Contoh: 100.000',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nominal wajib diisi';
                      }
                      final parsed = double.tryParse(
                        val.replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                      if (parsed == null || parsed <= 0) {
                        return 'Masukkan nominal yang valid (> 0)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (Opsional)',
                      hintText: 'Contoh: Bayar tagihan listrik',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      final raw = amountController.text.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      final amount = double.tryParse(raw) ?? 0;
                      final note = noteController.text.trim();

                      if (service.isBalanceInsufficient(
                        fromWalletId,
                        amount,
                      )) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Saldo Tidak Mencukupi'),
                            content: Text(
                              'Saldo ${fromWallet?.name ?? 'dompet asal'} tidak cukup (sisa ${CurrencyFormatter.format(fromBalance)}). Apakah Anda yakin ingin meneruskan transfer?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Batal'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  service.transferBalance(
                                    fromWalletId: fromWalletId,
                                    toWalletId: toWalletId,
                                    amount: amount,
                                    title: note,
                                  );
                                  Navigator.pop(sheetCtx);
                                },
                                child: const Text('Teruskan'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      service.transferBalance(
                        fromWalletId: fromWalletId,
                        toWalletId: toWalletId,
                        amount: amount,
                        title: note,
                      );
                      Navigator.pop(sheetCtx);
                    },
                    child: const Text(
                      'Pindahkan Saldo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ── Sheet Input Transaksi (Pemasukan / Pengeluaran) ─────────────────────────

void showTransactionInputSheet(
  BuildContext context,
  TransactionService service,
  TransactionType type,
) {
  final isIncome = type == TransactionType.income;
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String selectedWalletId = service.activeWallets.isNotEmpty
      ? service.activeWallets.first.id
      : TransactionService.defaultWalletId;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        isIncome
                            ? Icons.arrow_circle_up
                            : Icons.arrow_circle_down,
                        color: isIncome ? Colors.green : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isIncome
                            ? 'Tambah Uang (Pemasukan)'
                            : 'Kurang Uang (Pengeluaran)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (service.activeWallets.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      key: const Key('dropdown_select_wallet'),
                      initialValue: selectedWalletId,
                      decoration: InputDecoration(
                        labelText: isIncome
                            ? 'Pilih Dompet Tujuan'
                            : 'Pilih Dompet Asal',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: service.activeWallets.map((w) {
                        final bal = service.getWalletBalance(w.id);
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text(
                            '${w.name} (Sisa: ${CurrencyFormatter.format(bal)})',
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            selectedWalletId = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: amountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Nominal (Rp)',
                      hintText: 'Contoh: 50.000',
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nominal wajib diisi';
                      }
                      final parsed = double.tryParse(
                        value.replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                      if (parsed == null || parsed <= 0) {
                        return 'Masukkan nominal yang valid (> 0)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText:
                          isIncome ? 'Catatan / Keterangan (opsional)' : 'Keperluan',
                      hintText: isIncome
                          ? 'Contoh: Gaji, Bonus, Transfer'
                          : 'Contoh: Makan siang, Bensin',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      final raw = amountController.text.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      final amount = double.tryParse(raw) ?? 0;
                      final note = noteController.text.trim();

                      if (!isIncome &&
                          service.isBalanceInsufficient(
                            selectedWalletId,
                            amount,
                          )) {
                        final walletBalance =
                            service.getWalletBalance(selectedWalletId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Saldo tidak cukup. Sisa: ${CurrencyFormatter.format(walletBalance)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                        return;
                      }

                      if (isIncome) {
                        service.addIncome(
                          amount,
                          walletId: selectedWalletId,
                          title: note,
                        );
                      } else {
                        service.addExpense(
                          amount,
                          walletId: selectedWalletId,
                          title: note,
                        );
                      }
                      Navigator.pop(sheetContext);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isIncome ? AppColors.income : AppColors.expense,
                      foregroundColor: isIncome
                          ? AppColors.background
                          : Colors.white,
                    ),
                    child: Text(
                      isIncome ? 'Simpan Pemasukan' : 'Simpan Pengeluaran',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ── Quick Action Sheet (FAB +) ──────────────────────────────────────────────

void showQuickActionSheet(
  BuildContext context,
  TransactionService service,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Catat Transaksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih jenis transaksi yang ingin Anda catat',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('button_add_income'),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        showTransactionInputSheet(
                          context,
                          service,
                          TransactionType.income,
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.income.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.income.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.south_west_rounded,
                                color: AppColors.income,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tambah Uang',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.income,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pemasukan',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      key: const Key('button_add_expense'),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        showTransactionInputSheet(
                          context,
                          service,
                          TransactionType.expense,
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.expense.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.north_east_rounded,
                                color: AppColors.expense,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Kurang Uang',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.expense,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pengeluaran',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('button_transfer_quick'),
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  showTransferSheet(context, service);
                },
                icon: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.transfer,
                ),
                label: const Text(
                  'Pindah Saldo (Transfer)',
                  style: TextStyle(
                    color: AppColors.transfer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.transfer.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ── Dialog Konfirmasi ───────────────────────────────────────────────────────

void confirmDeleteWallet(
  BuildContext context,
  TransactionService service,
  Wallet wallet,
) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Hapus Dompet'),
      content: Text(
        'Yakin ingin menghapus dompet "${wallet.name}" ini?\n\nRiwayat transaksi yang menggunakan dompet ini akan tetap tersimpan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(dialogCtx);
            service.deleteWallet(wallet.id);
          },
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
}

void confirmDeleteTransaction(
  BuildContext context,
  TransactionService service,
  TransactionRecord item,
) {
  final String targetName = item.title.trim().isNotEmpty
      ? 'transaksi "${item.title}"'
      : 'transaksi';

  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Hapus Transaksi'),
      content: Text('Yakin ingin menghapus $targetName ini?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(dialogCtx);
            service.deleteTransaction(item.id);
          },
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
}

void confirmClearAllTransactions(
  BuildContext context,
  TransactionService service,
) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Hapus Riwayat Transaksi'),
      content: const Text(
        'Yakin ingin menghapus seluruh riwayat transaksi ini?\n\nSemua catatan mutasi akan dihapus dan saldo dompet akan dikembalikan ke 0.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            Navigator.pop(dialogCtx);
            service.clearAll();
          },
          child: const Text('Hapus Semua'),
        ),
      ],
    ),
  );
}

void confirmRestartApp(
  BuildContext context,
  TransactionService service,
) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Mulai dari Awal?'),
        ],
      ),
      content: const Text(
        'Tindakan ini akan menghapus semua riwayat transaksi, mereset daftar dompet, dan mengembalikan Anda ke halaman pembuka aplikasi (Welcome Page).\n\nApakah Anda yakin ingin memulai aplikasi dari awal?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(dialogCtx);
            await PreferenceService.setHasSeenWelcome(false);
            service.clearAll(resetWallets: true);
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  maintainState: true,
                  builder: (_) => WelcomePage(service: service),
                ),
                (route) => false,
              );
            }
          },
          child: const Text('Mulai dari Awal'),
        ),
      ],
    ),
  );
}
