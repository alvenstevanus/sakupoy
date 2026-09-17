enum TransactionType {
  income,
  expense,
}

enum TimeFilter {
  all('Semua'),
  last3Days('3 Hari Terakhir'),
  last7Days('7 Hari Terakhir'),
  last30Days('30 Hari Terakhir');

  final String label;
  const TimeFilter(this.label);
}

class MonthYear {
  final int year;
  final int month;

  const MonthYear(this.year, this.month);

  static const List<String> monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String get monthName => monthNames[month - 1];
  String get label => '$monthName $year';

  MonthYear previous() {
    if (month == 1) {
      return MonthYear(year - 1, 12);
    }
    return MonthYear(year, month - 1);
  }

  MonthYear next() {
    if (month == 12) {
      return MonthYear(year + 1, 1);
    }
    return MonthYear(year, month + 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYear &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => Object.hash(year, month);
}

class TransactionRecord {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;

  const TransactionRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
  });
}
