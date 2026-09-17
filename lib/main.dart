import 'package:flutter/material.dart';
import 'models/transaction.dart';
import 'screens/welcome_page.dart';
import 'services/preference_service.dart';
import 'services/transaction_service.dart';
import 'utils/currency_formatter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSeenWelcome = await PreferenceService.hasSeenWelcome();
  runApp(SakuPoyApp(hasSeenWelcome: hasSeenWelcome));
}

class SakuPoyApp extends StatelessWidget {
  final bool hasSeenWelcome;
  const SakuPoyApp({super.key, this.hasSeenWelcome = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SakuPoy - Pencatatan Keuangan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
      ),
      home: hasSeenWelcome ? const FinanceHomePage() : const WelcomePage(),
    );
  }
}

class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({super.key});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  final TransactionService _service = TransactionService();
  String _selectedFilter = 'all';

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

  List<DropdownMenuItem<String>> _buildDropdownItems([List<MonthYear>? availableMonths]) {
    final months = availableMonths ?? _service.getAvailableMonths();
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(
        value: 'all',
        child: Text('Semua Transaksi'),
      ),
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

  void _showTransactionInputSheet(BuildContext context, TransactionType type) {
    final isIncome = type == TransactionType.income;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
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
                      isIncome ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                      color: isIncome ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isIncome ? 'Tambah Uang (Pemasukan)' : 'Kurang Uang (Pengeluaran)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    ThousandsSeparatorInputFormatter(),
                  ],
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
                    final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
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
                    hintText: isIncome ? 'Contoh: Gaji, Transfer' : 'Contoh: Makan siang, Bensin',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final rawNumber = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                      final amount = double.parse(rawNumber);
                      final note = noteController.text;

                      if (isIncome) {
                        _service.addIncome(amount, title: note);
                      } else {
                        _service.addExpense(amount, title: note);
                      }

                      Navigator.pop(sheetContext);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isIncome ? 'Simpan Pemasukan' : 'Simpan Pengeluaran',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SakuPoy - Catatan Keuangan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Catatan',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_service.transactions.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Reset Catatan'),
                    content: const Text('Hapus seluruh riwayat transaksi dan kembalikan saldo ke 0?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          _service.clearAll();
                          Navigator.pop(dialogCtx);
                        },
                        child: const Text('Hapus Semua', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Ringkasan Total Uang (Fokus Fungsi & UX)
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'TOTAL SALDO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(_service.totalBalance),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _service.totalBalance >= 0
                              ? Colors.black87
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Masuk (+)',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(_service.totalIncome),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 30, width: 1, color: Colors.grey.shade300),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Keluar (-)',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(_service.totalExpense),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Tombol Aksi Cepat (Tambah & Kurang)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('button_add_income'),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Tambah Uang',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _showTransactionInputSheet(
                          context,
                          TransactionType.income,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('button_add_expense'),
                        icon: const Icon(Icons.remove, color: Colors.white),
                        label: const Text(
                          'Kurang Uang',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => _showTransactionInputSheet(
                          context,
                          TransactionType.expense,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (_service.transactions.isNotEmpty)
                          Text(
                            '${_getFilteredTransactions().length} transaksi (${_getActiveFilterLabel()})',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: const Key('dropdown_filter'),
                          value: _selectedFilter,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
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
                      return Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              const Text(
                                'Belum ada catatan keuangan',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gunakan tombol "+ Tambah Uang" atau "- Kurang Uang" untuk mulai mencatat.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.filter_alt_off_outlined, size: 44, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada transaksi pada ${_getActiveFilterLabel()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedFilter = 'all';
                                  });
                                },
                                child: const Text('Tampilkan Semua Transaksi'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isIncome = item.type == TransactionType.income;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                            child: Icon(
                              isIncome ? Icons.south_west : Icons.north_east,
                              color: isIncome ? Colors.green.shade800 : Colors.red.shade800,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}/${item.date.year} ${item.date.hour.toString().padLeft(2, '0')}:${item.date.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(item.amount)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isIncome ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                tooltip: 'Hapus',
                                onPressed: () {
                                  _service.deleteTransaction(item.id);
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
      ),
    );
  }
}
