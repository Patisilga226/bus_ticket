class Bus {
  final int id;
  final String busNumber;
  final String route;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int totalSeats;
  final int availableSeats;
  final double price;
  final DateTime createdAt;

  Bus({
    required this.id,
    required this.busNumber,
    required this.route,
    required this.departureTime,
    required this.arrivalTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.price,
    required this.createdAt,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double parsePrice(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    String parseString(dynamic value, {String fallback = ''}) {
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }

    return Bus(
      id: parseInt(json['id']),
      busNumber: parseString(json['bus_number']),
      route: parseString(json['route']),
      departureTime: parseDate(json['departure_time']),
      arrivalTime: parseDate(json['arrival_time']),
      totalSeats: parseInt(json['total_seats']),
      availableSeats: parseInt(json['available_seats']),
      price: parsePrice(json['price']),
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bus_number': busNumber,
      'route': route,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'total_seats': totalSeats,
      'available_seats': availableSeats,
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Bus copyWith({
    int? id,
    String? busNumber,
    String? route,
    DateTime? departureTime,
    DateTime? arrivalTime,
    int? totalSeats,
    int? availableSeats,
    double? price,
    DateTime? createdAt,
  }) {
    return Bus(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      route: route ?? this.route,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
