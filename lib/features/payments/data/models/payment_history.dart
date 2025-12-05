/// Payment history model - represents a completed payment transaction
class PaymentHistory {
  final int id;
  final String transactionId;
  final String type; // 'subscription', 'superlike_pack', 'boost', etc.
  final String status; // 'completed', 'pending', 'failed', 'refunded'
  final double amount;
  final String currency;
  final String description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;
  final Map<String, dynamic> metadata; // additional transaction data

  PaymentHistory({
    required this.id,
    required this.transactionId,
    required this.type,
    required this.status,
    required this.amount,
    required this.currency,
    required this.description,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
    this.metadata = const {},
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'] != null ? ((json['id'] is int) ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0) : 0,
      transactionId: json['transaction_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'USD',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      failureReason: json['failure_reason']?.toString(),
      metadata: json['metadata'] != null && json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'type': type,
      'status': status,
      'amount': amount,
      'currency': currency,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (failureReason != null) 'failure_reason': failureReason,
      'metadata': metadata,
    };
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  /// Check if payment was successful
  bool get isSuccessful => status == 'completed';

  /// Check if payment is pending
  bool get isPending => status == 'pending';

  /// Check if payment failed
  bool get isFailed => status == 'failed';

  /// Check if payment was refunded
  bool get isRefunded => status == 'refunded';

  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case 'completed':
        return 'success';
      case 'pending':
        return 'warning';
      case 'failed':
        return 'error';
      case 'refunded':
        return 'info';
      default:
        return 'default';
    }
  }
}
