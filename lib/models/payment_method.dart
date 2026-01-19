enum PaymentMethodType {
  creditCard,
  debitCard,
}

enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  unknown,
}

class PaymentMethod {
  final String id;
  final String userId;
  final PaymentMethodType type;
  final CardBrand cardBrand;
  final String lastFourDigits;
  final String expiryMonth;
  final String expiryYear;
  final String? cardholderName;
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.cardBrand,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
    this.cardholderName,
    this.isDefault = false,
    required this.createdAt,
  });

  String get displayName {
    final brandName = cardBrand.name.toUpperCase();
    return '$brandName **** $lastFourDigits';
  }

  String get expiryDate => '$expiryMonth/$expiryYear';

  bool get isExpired {
    final now = DateTime.now();
    final expYear = int.tryParse('20$expiryYear') ?? 0;
    final expMonth = int.tryParse(expiryMonth) ?? 0;

    if (expYear < now.year) return true;
    if (expYear == now.year && expMonth < now.month) return true;
    return false;
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: PaymentMethodType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PaymentMethodType.creditCard,
      ),
      cardBrand: CardBrand.values.firstWhere(
        (b) => b.name == json['card_brand'],
        orElse: () => CardBrand.unknown,
      ),
      lastFourDigits: json['last_four_digits'] as String,
      expiryMonth: json['expiry_month'] as String,
      expiryYear: json['expiry_year'] as String,
      cardholderName: json['cardholder_name'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'card_brand': cardBrand.name,
      'last_four_digits': lastFourDigits,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'cardholder_name': cardholderName,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PaymentMethod copyWith({
    String? id,
    String? userId,
    PaymentMethodType? type,
    CardBrand? cardBrand,
    String? lastFourDigits,
    String? expiryMonth,
    String? expiryYear,
    String? cardholderName,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      cardBrand: cardBrand ?? this.cardBrand,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardholderName: cardholderName ?? this.cardholderName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static CardBrand detectCardBrand(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanNumber.isEmpty) return CardBrand.unknown;

    if (cleanNumber.startsWith('4')) return CardBrand.visa;
    if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
      return CardBrand.mastercard;
    }
    if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      return CardBrand.amex;
    }
    if (cleanNumber.startsWith('6')) return CardBrand.discover;

    return CardBrand.unknown;
  }
}
