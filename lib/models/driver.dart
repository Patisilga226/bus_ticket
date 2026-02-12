class Driver {
  final int id;
  final int userId;
  final int? busId;
  final DateTime assignedAt;
  final String employeeName;
  final String employeeEmail;
  final String? busNumber;
  final String? route;

  Driver({
    required this.id,
    required this.userId,
    this.busId,
    required this.assignedAt,
    required this.employeeName,
    required this.employeeEmail,
    this.busNumber,
    this.route,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Driver(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      busId: json['bus_id'] == null ? null : parseInt(json['bus_id']),
      assignedAt: parseDate(json['assigned_at']),
      employeeName: (json['employee_name'] ?? '').toString(),
      employeeEmail: (json['employee_email'] ?? '').toString(),
      busNumber: json['bus_number']?.toString(),
      route: json['route']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bus_id': busId,
      'assigned_at': assignedAt.toIso8601String(),
      'employee_name': employeeName,
      'employee_email': employeeEmail,
      'bus_number': busNumber,
      'route': route,
    };
  }

  Driver copyWith({
    int? id,
    int? userId,
    int? busId,
    DateTime? assignedAt,
    String? employeeName,
    String? employeeEmail,
    String? busNumber,
    String? route,
  }) {
    return Driver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      busId: busId ?? this.busId,
      assignedAt: assignedAt ?? this.assignedAt,
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      busNumber: busNumber ?? this.busNumber,
      route: route ?? this.route,
    );
  }
}
