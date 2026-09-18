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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDeleted': isDeleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<dynamic, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      isDeleted: (map['isDeleted'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
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
