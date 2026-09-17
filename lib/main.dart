import 'package:flutter/material.dart';

import 'models/transaction.dart';
import 'models/wallet.dart';
import 'screens/welcome_page.dart';
import 'services/preference_service.dart';
import 'services/transaction_service.dart';
import 'theme/app_theme.dart';
import 'utils/currency_formatter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSeenWelcome = await PreferenceService.hasSeenWelcome();
  runApp(SakuPoyApp(hasSeenWelcome: hasSeenWelcome));
}

class SakuPoyApp extends StatelessWidget {
  final bool hasSeenWelcome;
  final TransactionService? service;
  const SakuPoyApp({super.key, this.hasSeenWelcome = true, this.service});

  @override
  Widget build(BuildContext context) {
    final effectiveService = service ?? TransactionService();
    return MaterialApp(
      title: 'SakuPoy - Pencatatan Keuangan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: hasSeenWelcome
          ? FinanceHomePage(service: effectiveService)
          : WelcomePage(service: effectiveService),
    );
  }
}

class FinanceHomePage extends StatefulWidget {
  final TransactionService? service;
  const FinanceHomePage({super.key, this.service});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  late final TransactionService _service =
      widget.service ?? TransactionService();
  String _selectedFilter = 'all';
  int _currentTabIndex = 0;

  List<TransactionRecord> _getFilteredTransactions() {
    if (_selectedFilter == 'all') {
      return _service.getFilteredTransactions(TimeFilter.all);
    } else if (_selectedFilter == 'last3Days') {
      return _service.getFilteredTransactions(TimeFilter.last3Days);
    } else if (_selectedFilter == 'last7Days') {
      return _service.getFilteredTransactions(TimeFilter.last7Days);
    } else if (_selectedFilter == 'last30Days') {
      return _service.getFilteredTransactions(TimeFilter.last30Days);
    } else if (_selectedFilter.startsWith('month_')) {
      final parts = _selectedFilter.split('_');
      final year = int.parse(parts[1]);
      final month = int.parse(parts[2]);
      return _service.getTransactionsByMonth(MonthYear(year, month));
    }
    return _service.transactions;
  }

  String _getActiveFilterLabel() {
    if (_selectedFilter == 'all') {
      return 'Semua Transaksi';
    } else if (_selectedFilter == 'last3Days') {
      return '3 Hari Terakhir';
    } else if (_selectedFilter == 'last7Days') {
      return '7 Hari Terakhir';
    } else if (_selectedFilter == 'last30Days') {
      return '30 Hari Terakhir';
    } else if (_selectedFilter.startsWith('month_')) {
      final parts = _selectedFilter.split('_');
      final year = int.parse(parts[1]);
      final month = int.parse(parts[2]);
      return MonthYear(year, month).label;
    }
    return 'Semua Transaksi';
  }

  List<DropdownMenuItem<String>> _buildDropdownItems([
    List<MonthYear>? availableMonths,
  ]) {
    final months = availableMonths ?? _service.getAvailableMonths();
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'all', child: Text('Semua Transaksi')),
      const DropdownMenuItem(
        value: 'last3Days',
        child: Text('3 Hari Terakhir'),
      ),
      const DropdownMenuItem(
        value: 'last7Days',
        child: Text('7 Hari Terakhir'),
      ),
      const DropdownMenuItem(
        value: 'last30Days',
        child: Text('30 Hari Terakhir'),
      ),
    ];

    // Bulan yang ditampilkan dibatasi dari bulan sekarang hingga bulan transaksi paling awal
    for (final my in months) {
      items.add(
        DropdownMenuItem(
          value: 'month_${my.year}_${my.month}',
          child: Text(my.label),
        ),
      );
    }

    return items;
  }

  void _showAddWalletDialog(BuildContext context) {
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

                    _service.createWallet(walletName, initialBalance: balance);
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

  void _showTransferSheet(BuildContext context) {
    if (_service.activeWallets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dibutuhkan minimal 2 dompet aktif untuk memindahkan saldo.',
          ),
        ),
      );
      return;
    }

    String fromWalletId = _service.activeWallets.first.id;
    String toWalletId = _service.activeWallets[1].id;
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
            final fromWallet = _service.getWalletById(fromWalletId);
            final fromBalance = _service.getWalletBalance(fromWalletId);

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
                      items: _service.activeWallets.map((w) {
                        final bal = _service.getWalletBalance(w.id);
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
                              toWalletId = _service.activeWallets
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
                      items: _service.activeWallets
                          .where((w) => w.id != fromWalletId)
                          .map((w) {
                            final bal = _service.getWalletBalance(w.id);
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
                        labelText: 'Catatan (opsional)',
                        hintText: 'Contoh: Tarik tunai ATM, Top up e-wallet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          final raw = amountController.text.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          final amount = double.parse(raw);
                          final note = noteController.text;

                          if (_service.isBalanceInsufficient(
                            fromWalletId,
                            amount,
                          )) {
                            showDialog(
                              context: context,
                              builder: (confirmCtx) => AlertDialog(
                                title: const Text('Saldo Tidak Mencukupi'),
                                content: Text(
                                  'Saldo di ${fromWallet?.name ?? 'dompet ini'} hanya ${CurrencyFormatter.format(fromBalance)}. Transfer ini akan membuat saldo dompet menjadi minus. Tetap lanjutkan?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(confirmCtx),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(confirmCtx);
                                      _service.transferBalance(
                                        fromWalletId: fromWalletId,
                                        toWalletId: toWalletId,
                                        amount: amount,
                                        title: note,
                                      );
                                      Navigator.pop(sheetCtx);
                                    },
                                    child: const Text(
                                      'Teruskan',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          _service.transferBalance(
                            fromWalletId: fromWalletId,
                            toWalletId: toWalletId,
                            amount: amount,
                            title: note,
                          );
                          Navigator.pop(sheetCtx);
                        }
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

  void _showTransactionInputSheet(BuildContext context, TransactionType type) {
    final isIncome = type == TransactionType.income;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String selectedWalletId = _service.activeWallets.isNotEmpty
        ? _service.activeWallets.first.id
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
                    if (_service.activeWallets.isNotEmpty) ...[
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
                        items: _service.activeWallets.map((w) {
                          final bal = _service.getWalletBalance(w.id);
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
                        labelText: 'Catatan / Keterangan (opsional)',
                        hintText: isIncome
                            ? 'Contoh: Gaji, Transfer'
                            : 'Contoh: Makan siang, Bensin',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          final rawNumber = amountController.text.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          final amount = double.parse(rawNumber);
                          final note = noteController.text;

                          if (!isIncome &&
                              _service.isBalanceInsufficient(
                                selectedWalletId,
                                amount,
                              )) {
                            final walletName =
                                _service
                                    .getWalletById(selectedWalletId)
                                    ?.name ??
                                'dompet ini';
                            final currentBal = _service.getWalletBalance(
                              selectedWalletId,
                            );

                            showDialog(
                              context: context,
                              builder: (confirmCtx) => AlertDialog(
                                title: const Text('Saldo Tidak Mencukupi'),
                                content: Text(
                                  'Saldo di $walletName hanya ${CurrencyFormatter.format(currentBal)}. Pengeluaran ini akan membuat saldo dompet menjadi minus. Tetap lanjutkan?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(confirmCtx),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(confirmCtx);
                                      _service.addExpense(
                                        amount,
                                        walletId: selectedWalletId,
                                        title: note,
                                      );
                                      Navigator.pop(sheetContext);
                                    },
                                    child: const Text(
                                      'Teruskan',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          if (isIncome) {
                            _service.addIncome(
                              amount,
                              walletId: selectedWalletId,
                              title: note,
                            );
                          } else {
                            _service.addExpense(
                              amount,
                              walletId: selectedWalletId,
                              title: note,
                            );
                          }

                          Navigator.pop(sheetContext);
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: isIncome
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        isIncome ? 'Simpan Pemasukan' : 'Simpan Pengeluaran',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  void _confirmDeleteWallet(BuildContext context, Wallet wallet) {
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
              _service.deleteWallet(wallet.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, TransactionRecord item) {
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
              _service.deleteTransaction(item.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllTransactions(BuildContext context) {
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
              _service.clearAll();
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _confirmRestartApp(BuildContext context) {
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
              _service.clearAll(resetWallets: true);
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    maintainState: true,
                    builder: (_) => WelcomePage(service: _service),
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

  void _showQuickActionSheet(BuildContext context) {
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
                          _showTransactionInputSheet(
                            context,
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        key: const Key('button_add_expense'),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          _showTransactionInputSheet(
                            context,
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Ringkasan Total Saldo (Sleek Dark Theme)
            Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL SALDO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Aktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      CurrencyFormatter.format(_service.totalBalance),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: _service.totalBalance >= 0
                            ? AppColors.primary
                            : AppColors.expense,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 12,
                                      color: AppColors.income,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Total Masuk',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(
                                    _service.totalIncome,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.income,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: AppColors.border,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      size: 12,
                                      color: AppColors.expense,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Total Keluar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(
                                    _service.totalExpense,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.expense,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Dompet Saya & Sumber Dana (Pindah Saldo Opsi A & Tambah Dompet)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Dompet Saya',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${_service.activeWallets.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        key: const Key('button_transfer_balance'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.transfer,
                          side: BorderSide(
                            color: AppColors.transfer.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text(
                          'Pindah',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _showTransferSheet(context),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.tonalIcon(
                        key: const Key('button_add_wallet'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.surfaceVariant,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Tambah',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _showAddWalletDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              height: 94,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _service.activeWallets.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final wallet = _service.activeWallets[index];
                  final balance = _service.getWalletBalance(wallet.id);
                  final isNegative = balance < 0;

                  return Container(
                    width: 155,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                wallet.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_service.activeWallets.length > 1)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  padding: EdgeInsets.zero,
                                  color: AppColors.surfaceVariant,
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Hapus Dompet',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'delete') {
                                      _confirmDeleteWallet(context, wallet);
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(balance),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isNegative
                                ? AppColors.expense
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // 3. Header Riwayat & Filter Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Riwayat Mutasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_service.transactions.isNotEmpty)
                        Text(
                          '${_getFilteredTransactions().length} transaksi (${_getActiveFilterLabel()})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: const Key('dropdown_filter'),
                        value: _selectedFilter,
                        dropdownColor: AppColors.surfaceVariant,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                        items: _buildDropdownItems(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedFilter = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 4. Daftar Riwayat Transaksi (Terfilter)
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_service.transactions.isEmpty) {
                    return const Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Belum ada catatan keuangan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gunakan tombol "+" di tengah untuk mulai mencatat transaksi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final filtered = _getFilteredTransactions();

                  if (filtered.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.filter_alt_off_outlined,
                              size: 44,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tidak ada transaksi pada ${_getActiveFilterLabel()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedFilter = 'all';
                                });
                              },
                              icon: const Icon(
                                Icons.refresh,
                                color: AppColors.primary,
                              ),
                              label: const Text(
                                'Tampilkan Semua Transaksi',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isIncome = item.type == TransactionType.income;
                      final isTransfer = item.type == TransactionType.transfer;

                      final sourceWallet = _service.getWalletById(
                        item.walletId,
                      );
                      final destWallet = item.destinationWalletId != null
                          ? _service.getWalletById(item.destinationWalletId!)
                          : null;

                      final walletBadgeText = isTransfer
                          ? '${sourceWallet?.name ?? 'Dompet'} \u2192 ${destWallet?.name ?? 'Dompet'}'
                          : (sourceWallet?.name ?? 'Dompet');

                      Color iconBg;
                      IconData iconData;
                      Color iconColor;
                      if (isTransfer) {
                        iconBg = AppColors.transfer.withValues(alpha: 0.15);
                        iconData = Icons.swap_horiz;
                        iconColor = AppColors.transfer;
                      } else if (isIncome) {
                        iconBg = AppColors.income.withValues(alpha: 0.15);
                        iconData = Icons.south_west;
                        iconColor = AppColors.income;
                      } else {
                        iconBg = AppColors.expense.withValues(alpha: 0.15);
                        iconData = Icons.north_east;
                        iconColor = AppColors.expense;
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: iconBg,
                          child: Icon(iconData, color: iconColor, size: 20),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year} ${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                walletBadgeText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isTransfer
                                  ? CurrencyFormatter.format(item.amount)
                                  : '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(item.amount)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isTransfer
                                    ? AppColors.transfer
                                    : (isIncome
                                          ? AppColors.income
                                          : AppColors.expense),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                              tooltip: 'Hapus',
                              onPressed: () {
                                _confirmDeleteTransaction(context, item);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileTab(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. User Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengguna SakuPoy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kelola Keuangan Pribadi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Summary Stats Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_service.activeWallets.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Dompet Aktif',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: AppColors.transfer,
                            size: 24,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_service.transactions.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Total Transaksi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Settings / Options Section
              const Text(
                'Pengaturan Aplikasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_sweep_outlined,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Hapus Riwayat Transaksi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Kosongkan semua catatan mutasi',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () {
                        if (_service.transactions.isNotEmpty) {
                          _confirmClearAllTransactions(context);
                        }
                      },
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      key: const Key('button_restart_app_profile'),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.restart_alt,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Mulai Aplikasi dari Awal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                      subtitle: const Text(
                        'Reset data & atur ulang dari Welcome Page',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => _confirmRestartApp(context),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    const ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      title: Text(
                        'Tentang SakuPoy',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Versi 0.0.2 Beta',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTabIndex == 0 ? 'SakuPoy' : 'Profil Pengguna',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: const [],
      ),
      body: _currentTabIndex == 0
          ? _buildHomeTab(context)
          : _buildProfileTab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        key: const Key('button_center_action'),
        tooltip: 'Catat Transaksi',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        shape: const CircleBorder(),
        elevation: 3,
        onPressed: () => _showQuickActionSheet(context),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    key: const Key('tab_home'),
                    onTap: () => setState(() => _currentTabIndex = 0),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home_rounded,
                            color: _currentTabIndex == 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Beranda',
                            style: TextStyle(
                              color: _currentTabIndex == 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: _currentTabIndex == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                  InkWell(
                    key: const Key('tab_profile'),
                    onTap: () => setState(() => _currentTabIndex = 1),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            color: _currentTabIndex == 1
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Profil',
                            style: TextStyle(
                              color: _currentTabIndex == 1
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: _currentTabIndex == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
