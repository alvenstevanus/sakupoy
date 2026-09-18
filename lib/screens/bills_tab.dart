import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../services/bill_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/bill_card.dart';

class BillsTab extends StatelessWidget {
  final BillService billService;
  final void Function(Bill) onPayBill;
  final VoidCallback onAddBill;

  const BillsTab({
    super.key,
    required this.billService,
    required this.onPayBill,
    required this.onAddBill,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: billService,
      builder: (context, _) {
        final unpaid = billService.unpaidBills;
        final paid = billService.paidBills;
        final overdueCount = billService.overdueBillsCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header summary
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Belum Dibayar',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${unpaid.length} tagihan',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                            billService.totalUnpaidAmount,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.expense,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 48, width: 1, color: AppColors.border),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jatuh Tempo',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$overdueCount tagihan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: overdueCount > 0
                                ? AppColors.expense
                                : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          overdueCount > 0 ? 'Segera bayar!' : 'Aman 👍',
                          style: TextStyle(
                            fontSize: 12,
                            color: overdueCount > 0
                                ? AppColors.expense
                                : AppColors.income,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: (unpaid.isEmpty && paid.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 56,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada tagihan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tekan tombol + untuk menambah tagihan baru',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: onAddBill,
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Tagihan'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                      children: [
                        if (unpaid.isNotEmpty) ...[
                          const Text(
                            'Belum Dibayar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...unpaid.map(
                            (bill) => Dismissible(
                              key: Key(bill.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.expense.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.expense,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Tagihan'),
                                    content: Text(
                                      'Hapus tagihan "${bill.name}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Batal'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) =>
                                  billService.deleteBill(bill.id),
                              child: BillCard(
                                bill: bill,
                                onPay: () => onPayBill(bill),
                              ),
                            ),
                          ),
                        ],
                        if (paid.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Sudah Dibayar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...paid.take(10).map(
                            (bill) => Dismissible(
                              key: Key('${bill.id}_paid'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.expense.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.expense,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Riwayat'),
                                    content: Text(
                                      'Hapus riwayat tagihan "${bill.name}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Batal'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) =>
                                  billService.deleteBill(bill.id),
                              child: BillCard(
                                bill: bill,
                                onPay: () => onPayBill(bill),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
