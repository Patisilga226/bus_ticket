class Ticket {
  final int id;
  final int userId;
  final int busId;
  final int seatNumber;
  final String qrCode;
  final DateTime departureTime;
  final DateTime qrValidUntil;
  final String status;
  final DateTime createdAt;
  final String userName;
  final String userEmail;
  final String busNumber;
  final String route;
  final double price;

  Ticket({
    required this.id,
    required this.userId,
    required this.busId,
    required this.seatNumber,
    required this.qrCode,
    required this.departureTime,
    required this.qrValidUntil,
    required this.status,
    required this.createdAt,
    required this.userName,
    required this.userEmail,
    required this.busNumber,
    required this.route,
    required this.price,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double parsePrice(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    String parseString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    return Ticket(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      busId: parseInt(json['bus_id']),
      seatNumber: parseInt(json['seat_number']),
      qrCode: parseString(json['qr_code']),
      departureTime: parseDate(json['departure_time']),
      qrValidUntil: parseDate(json['qr_valid_until']),
      status: parseString(json['status'], fallback: 'pending'),
      createdAt: parseDate(json['created_at']),
      userName: parseString(json['user_name'], fallback: 'Passager'),
      userEmail: parseString(json['user_email'], fallback: 'N/A'),
      busNumber: parseString(json['bus_number']),
      route: parseString(json['route']),
      price: parsePrice(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bus_id': busId,
      'seat_number': seatNumber,
      'qr_code': qrCode,
      'departure_time': departureTime.toIso8601String(),
      'qr_valid_until': qrValidUntil.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'user_email': userEmail,
      'bus_number': busNumber,
      'route': route,
      'price': price,
    };
  }

  Ticket copyWith({
    int? id,
    int? userId,
    int? busId,
    int? seatNumber,
    String? qrCode,
    DateTime? departureTime,
    DateTime? qrValidUntil,
    String? status,
    DateTime? createdAt,
    String? userName,
    String? userEmail,
    String? busNumber,
    String? route,
    double? price,
  }) {
    return Ticket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      busId: busId ?? this.busId,
      seatNumber: seatNumber ?? this.seatNumber,
      qrCode: qrCode ?? this.qrCode,
      departureTime: departureTime ?? this.departureTime,
      qrValidUntil: qrValidUntil ?? this.qrValidUntil,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      busNumber: busNumber ?? this.busNumber,
      route: route ?? this.route,
      price: price ?? this.price,
    );
  }
}
