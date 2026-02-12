class Payment {
  final int id;
  final int? reservationId;
  final int userId;
  final double amount;
  final double deposit;
  final String type;
  final String status;
  final DateTime createdAt;

  Payment({
    required this.id,
    this.reservationId,
    required this.userId,
    required this.amount,
    required this.deposit,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      reservationId: json['reservation_id'] as int?,
      userId: json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'] as int,
      amount: (json['amount'] is int) ? (json['amount'] as int).toDouble() : json['amount'] as double,
      deposit: (json['deposit'] is int) ? (json['deposit'] as int).toDouble() : (json['deposit'] as double?) ?? 100.0,
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] is String 
          ? DateTime.parse(json['created_at']) 
          : json['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservation_id': reservationId,
      'user_id': userId,
      'amount': amount,
      'deposit': deposit,
      'type': type,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Payment copyWith({
    int? id,
    int? reservationId,
    int? userId,
    double? amount,
    double? deposit,
    String? type,
    String? status,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      deposit: deposit ?? this.deposit,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}