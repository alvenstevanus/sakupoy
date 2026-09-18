/// Frekuensi pengulangan tagihan
enum BillRecurrence {
  weekly('Mingguan'),
  monthly('Bulanan'),
  yearly('Tahunan');

  final String label;
  const BillRecurrence(this.label);
}

/// Model data untuk satu tagihan
class Bill {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isRecurring;
  final BillRecurrence? recurrence;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime createdAt;

  const Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.isRecurring,
    this.recurrence,
    required this.isPaid,
    this.paidAt,
    required this.createdAt,
  });

  /// Tagihan sudah lewat jatuh tempo dan belum dibayar
  bool get isOverdue {
    if (isPaid) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  /// Tagihan jatuh tempo hari ini dan belum dibayar
  bool get isDueToday {
    if (isPaid) return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  /// Hitung tanggal jatuh tempo berikutnya untuk tagihan berulang
  DateTime get nextDueDate {
    assert(isRecurring && recurrence != null,
        'nextDueDate only valid for recurring bills');
    switch (recurrence!) {
      case BillRecurrence.weekly:
        return dueDate.add(const Duration(days: 7));
      case BillRecurrence.monthly:
        final nextMonth = dueDate.month == 12
            ? DateTime(dueDate.year + 1, 1, dueDate.day)
            : DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
        return nextMonth;
      case BillRecurrence.yearly:
        return DateTime(dueDate.year + 1, dueDate.month, dueDate.day);
    }
  }

  Bill copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    bool? isRecurring,
    BillRecurrence? recurrence,
    bool? isPaid,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'recurrence': recurrence?.index,
      'isPaid': isPaid ? 1 : 0,
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Bill.fromMap(Map<dynamic, dynamic> map) {
    final recurrenceIndex = map['recurrence'];
    return Bill(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      isRecurring: (map['isRecurring'] as int) == 1,
      recurrence: recurrenceIndex != null
          ? BillRecurrence.values[recurrenceIndex as int]
          : null,
      isPaid: (map['isPaid'] as int) == 1,
      paidAt: map['paidAt'] != null
          ? DateTime.parse(map['paidAt'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
