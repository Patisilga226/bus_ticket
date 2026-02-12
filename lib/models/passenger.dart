class Passenger {
  final String id;
  final String name;
  final String city;
  final int totalTrips;
  final String status;
  final String? lastTravelDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Passenger({
    required this.id,
    required this.name,
    required this.city,
    required this.totalTrips,
    required this.status,
    this.lastTravelDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      totalTrips: json['totalTrips'] as int,
      status: json['status'] as String,
      lastTravelDate: json['lastTravelDate'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'totalTrips': totalTrips,
      'status': status,
      'lastTravelDate': lastTravelDate,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Passenger copyWith({
    String? id,
    String? name,
    String? city,
    int? totalTrips,
    String? status,
    String? lastTravelDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Passenger(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      totalTrips: totalTrips ?? this.totalTrips,
      status: status ?? this.status,
      lastTravelDate: lastTravelDate ?? this.lastTravelDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}