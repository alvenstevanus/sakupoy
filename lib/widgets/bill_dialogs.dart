import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../services/bill_service.dart';
import '../services/transaction_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

// ── Sheet Tambah Tagihan ───────────────────────────────────────────────────

void showAddBillSheet(BuildContext context, BillService billService) {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
  bool isRecurring = false;
  BillRecurrence selectedRecurrence = BillRecurrence.monthly;
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 24,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
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
                  const Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: AppColors.transfer,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tambah Tagihan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tagihan',
                      hintText: 'Contoh: Listrik, Netflix, Cicilan HP',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama tagihan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Nominal (Rp)',
                      hintText: 'Contoh: 150.000',
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
                  // Date picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 3),
                        ),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tanggal Jatuh Tempo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Recurring toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tagihan Berulang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Switch(
                          value: isRecurring,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setSheetState(() => isRecurring = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isRecurring) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BillRecurrence>(
                      initialValue: selectedRecurrence,
                      decoration: const InputDecoration(
                        labelText: 'Frekuensi Pengulangan',
                        border: OutlineInputBorder(),
                      ),
                      items: BillRecurrence.values.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r.label),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedRecurrence = val);
                        }
                      },
                    ),
                  ],
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
                      billService.addBill(
                        name: nameController.text.trim(),
                        amount: amount,
                        dueDate: selectedDate,
                        isRecurring: isRecurring,
                        recurrence:
                            isRecurring ? selectedRecurrence : null,
                      );
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tagihan berhasil ditambahkan'),
                        ),
                      );
                    },
                    child: const Text(
                      'Simpan Tagihan',
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

// ── Dialog Pembayaran Tagihan ───────────────────────────────────────────────

void showPayBillDialog(
  BuildContext context,
  Bill bill,
  BillService billService,
  TransactionService service,
) {
  if (service.activeWallets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak ada dompet aktif.')),
    );
    return;
  }

  String selectedWalletId = service.activeWallets.first.id;

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final wallet = service.getWalletById(selectedWalletId);
          final walletBalance = service.getWalletBalance(selectedWalletId);
          final isInsufficient = walletBalance < bill.amount;

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bayar ${bill.name}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        CurrencyFormatter.format(bill.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Bayar dari dompet:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedWalletId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: service.activeWallets.map((w) {
                    final bal = service.getWalletBalance(w.id);
                    return DropdownMenuItem(
                      value: w.id,
                      child: Text(
                        '${w.name} (${CurrencyFormatter.format(bal)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedWalletId = val);
                    }
                  },
                ),
                if (isInsufficient) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.expense.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.expense,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Saldo ${wallet?.name ?? 'dompet'} tidak cukup (${CurrencyFormatter.format(walletBalance)})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.expense,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: isInsufficient
                    ? null
                    : () {
                        Navigator.pop(dialogCtx);
                        billService.payBill(
                          bill.id,
                          selectedWalletId,
                          service,
                        );
                        final isRecurring =
                            bill.isRecurring && bill.recurrence != null;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isRecurring
                                  ? '${bill.name} lunas! Tagihan berikutnya sudah dijadwalkan.'
                                  : '${bill.name} berhasil dibayar.',
                            ),
                          ),
                        );
                      },
                child: const Text('Bayar Sekarang'),
              ),
            ],
          );
        },
      );
    },
  );
}
