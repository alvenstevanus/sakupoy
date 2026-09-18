import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class HistoryTab extends StatefulWidget {
  final TransactionService service;
  final void Function(TransactionRecord) onDeleteTransaction;
  final VoidCallback onClearAllTransactions;
  final VoidCallback onAddTransaction;

  const HistoryTab({
    super.key,
    required this.service,
    required this.onDeleteTransaction,
    required this.onClearAllTransactions,
    required this.onAddTransaction,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _selectedFilter = 'all';

  List<TransactionRecord> _getFilteredTransactions() {
    if (_selectedFilter == 'all') {
      return widget.service.getFilteredTransactions(TimeFilter.all);
    } else if (_selectedFilter == 'last3Days') {
      return widget.service.getFilteredTransactions(TimeFilter.last3Days);
    } else if (_selectedFilter == 'last7Days') {
      return widget.service.getFilteredTransactions(TimeFilter.last7Days);
    } else if (_selectedFilter == 'last30Days') {
      return widget.service.getFilteredTransactions(TimeFilter.last30Days);
    } else if (_selectedFilter.startsWith('month_')) {
      final parts = _selectedFilter.split('_');
      final year = int.parse(parts[1]);
      final month = int.parse(parts[2]);
      return widget.service.getTransactionsByMonth(MonthYear(year, month));
    }
    return widget.service.transactions;
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
    final months = availableMonths ?? widget.service.getAvailableMonths();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        final filtered = _getFilteredTransactions();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                      if (widget.service.transactions.isNotEmpty)
                        Text(
                          '${filtered.length} transaksi (${_getActiveFilterLabel()})',
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

            // Transaction list
            Expanded(
              child: Builder(
                builder: (context) {
                  if (widget.service.transactions.isEmpty) {
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
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isIncome = item.type == TransactionType.income;
                      final isTransfer = item.type == TransactionType.transfer;

                      final sourceWallet = widget.service.getWalletById(
                        item.walletId,
                      );
                      final destWallet = item.destinationWalletId != null
                          ? widget.service.getWalletById(item.destinationWalletId!)
                          : null;

                      final walletBadgeText = isTransfer
                          ? '${sourceWallet?.name ?? 'Dompet'} → ${destWallet?.name ?? 'Dompet'}'
                          : (sourceWallet?.name ?? 'Dompet');

                      Color iconBg;
                      IconData iconData;
                      Color iconColor;
                      if (isTransfer) {
                        iconBg =
                            AppColors.transfer.withValues(alpha: 0.15);
                        iconData = Icons.swap_horiz;
                        iconColor = AppColors.transfer;
                      } else if (isIncome) {
                        iconBg = AppColors.income.withValues(alpha: 0.15);
                        iconData = Icons.south_west;
                        iconColor = AppColors.income;
                      } else {
                        iconBg =
                            AppColors.expense.withValues(alpha: 0.15);
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
                                widget.onDeleteTransaction(item);
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
}
