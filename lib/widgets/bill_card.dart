import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class BillCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onPay;
  final bool compact;

  const BillCard({
    super.key,
    required this.bill,
    this.onPay,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = bill.isOverdue;
    final isDueToday = bill.isDueToday;
    final borderColor = isOverdue
        ? AppColors.expense.withValues(alpha: 0.6)
        : isDueToday
            ? Colors.orange.withValues(alpha: 0.6)
            : AppColors.border;
    final dueDateStr =
        '${bill.dueDate.day.toString().padLeft(2, '0')}/${bill.dueDate.month.toString().padLeft(2, '0')}/${bill.dueDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverdue
                  ? AppColors.expense.withValues(alpha: 0.15)
                  : AppColors.transfer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOverdue
                  ? Icons.warning_amber_rounded
                  : Icons.receipt_long_outlined,
              color: isOverdue ? AppColors.expense : AppColors.transfer,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bill.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (bill.isRecurring)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.repeat,
                              size: 10,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              bill.recurrence?.label ?? '',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 10,
                      color: isOverdue ? AppColors.expense : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? 'Jatuh tempo: $dueDateStr (terlambat)'
                          : isDueToday
                              ? 'Jatuh tempo hari ini!'
                              : 'Jatuh tempo: $dueDateStr',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue
                            ? AppColors.expense
                            : isDueToday
                                ? Colors.orange
                                : AppColors.textSecondary,
                        fontWeight: (isOverdue || isDueToday)
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(bill.amount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
          if (!bill.isPaid && !compact) ...[
            const SizedBox(width: 8),
            Column(
              children: [
                FilledButton(
                  onPressed: onPay,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Bayar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!bill.isPaid && compact) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onPay,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Bayar',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
          if (bill.isPaid) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.income,
              size: 22,
            ),
          ],
        ],
      ),
    );
  }
}
