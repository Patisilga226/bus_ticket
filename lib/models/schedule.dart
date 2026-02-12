class Schedule {
  final String id;
  final String route;
  final String busId;
  final String departureTime;
  final String arrivalTime;
  final String frequency;
  final String duration;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Schedule({
    required this.id,
    required this.route,
    required this.busId,
    required this.departureTime,
    required this.arrivalTime,
    required this.frequency,
    required this.duration,
    required this.createdAt,
    this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      route: json['route'] as String,
      busId: json['busId'] as String,
      departureTime: json['departureTime'] as String,
      arrivalTime: json['arrivalTime'] as String,
      frequency: json['frequency'] as String,
      duration: json['duration'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route': route,
      'busId': busId,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'frequency': frequency,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Schedule copyWith({
    String? id,
    String? route,
    String? busId,
    String? departureTime,
    String? arrivalTime,
    String? frequency,
    String? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      route: route ?? this.route,
      busId: busId ?? this.busId,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}