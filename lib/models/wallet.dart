class Wallet {
  final String id;
  final String name;
  final bool isDeleted;
  final DateTime createdAt;

  const Wallet({
    required this.id,
    required this.name,
    this.isDeleted = false,
    required this.createdAt,
  });

  /// Daftar template dompet bawaan yang sering digunakan
  static const List<String> presetWallets = [
    'Tunai / Cash',
    'BRImo',
    'DANA',
    'BCA',
    'Mandiri',
    'BNI',
    'GoPay',
    'OVO',
    'ShopeePay',
  ];

  Wallet copyWith({
    String? id,
    String? name,
    bool? isDeleted,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isDeleted == other.isDeleted;

  @override
  int get hashCode => Object.hash(id, name, isDeleted);
}
