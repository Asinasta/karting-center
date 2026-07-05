/// Shared API models from `01-analysis/api/common/models.yaml`.
class Money {
  const Money({
    required this.amount,
    required this.currency,
  });

  factory Money.fromJson(Map<String, Object?> json) {
    return Money(
      amount: json['amount'] as int,
      currency: json['currency'] as String,
    );
  }

  /// Amount in kopecks.
  final int amount;
  final String currency;

  String get formatted {
    final rubles = amount ~/ 100;
    final kopecks = amount % 100;
    final rublesText = _groupThousands(rubles);
    if (kopecks == 0) {
      return '$rublesText ₽';
    }
    return '$rublesText,${kopecks.toString().padLeft(2, '0')} ₽';
  }
}

String _groupThousands(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write('\u2009');
    }
    buffer.write(text[i]);
  }
  return buffer.toString();
}

class Pagination {
  const Pagination({
    this.limit,
    this.offset,
    this.total,
  });

  factory Pagination.fromJson(Map<String, Object?> json) {
    return Pagination(
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
      total: json['total'] as int?,
    );
  }

  final int? limit;
  final int? offset;
  final int? total;
}
