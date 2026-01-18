enum TransactionType {
  used,
  purchased,
  bonus,
  refund,
}

class CreditTransaction {
  final String id;
  final String userId;
  final int amount;
  final TransactionType transactionType;
  final String? description;
  final DateTime createdAt;

  CreditTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.transactionType,
    this.description,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] as int,
      transactionType: _parseTransactionType(json['transaction_type'] as String),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'transaction_type': transactionType.name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static TransactionType _parseTransactionType(String type) {
    switch (type) {
      case 'used':
        return TransactionType.used;
      case 'purchased':
        return TransactionType.purchased;
      case 'bonus':
        return TransactionType.bonus;
      case 'refund':
        return TransactionType.refund;
      default:
        return TransactionType.used;
    }
  }
}
