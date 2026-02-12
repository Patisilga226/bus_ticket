# 📱 Guide d'Intégration Admin - API dans Flutter

## 1. SETUP INITIAL FLUTTER

### A. Dépendances requises (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0              # Pour les requêtes HTTP
  dio: ^5.3.0               # Alternative robuste à http
  provider: ^6.0.0          # State management
  shared_preferences: ^2.2.0 # Stockage local (tokens admin)
  charts_flutter: ^0.12.0   # Graphiques pour statistiques
  intl: ^0.19.0             # Formatage dates/devises
  table_calendar: ^3.0.0    # Calendrier pour planification
  flutter_local_notifications: ^14.0.0 # Notifications

dev_dependencies:
  flutter_test:
    sdk: flutter
```

Installez les dépendances:
```bash
flutter pub get
```

---

## 2. CONFIGURATION DE LA CONNEXION API ADMIN

### A. Créer un service HTTP Admin (lib/services/admin_api_service.dart)

```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  // En production: https://votre-api.com/api
  
  late Dio _dio;
  
  AdminApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(seconds: 15),
        receiveTimeout: Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    
    // Interceptor pour ajouter le token JWT admin
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('admin_jwt_token');
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
        onError: (error, handler) {
          // Gestion des erreurs globales
          if (error.response?.statusCode == 401) {
            // Token expiré, rediriger vers login admin
            print('Token admin expiré');
          }
          return handler.next(error);
        },
      ),
    );
  }
  
  // ===== AUTHENTIFICATION ADMIN =====
  
  Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      // Sauvegarder le token admin (la route /auth/login retourne `user`)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_jwt_token', response.data['token']);
      await prefs.setString('admin_id', response.data['user']['id'].toString());
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> adminLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_jwt_token');
    await prefs.remove('admin_id');
  }
  
  // ===== BUS - MANAGEMENT =====
  
  Future<List<Map<String, dynamic>>> getBuses({int? page, int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      
      final response = await _dio.get('/buses', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['buses']);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> createBus({
    required String busNumber,
    required String route,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required int totalSeats,
    required double price,
  }) async {
    try {
      final response = await _dio.post('/buses', data: {
        'bus_number': busNumber,
        'route': route,
        'departure_time': departureTime.toIso8601String(),
        'arrival_time': arrivalTime.toIso8601String(),
        'total_seats': totalSeats,
        'price': price,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateBus({
    required int busId,
    String? busNumber,
    String? route,
    DateTime? departureTime,
    DateTime? arrivalTime,
    int? totalSeats,
    double? price,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (busNumber != null) data['bus_number'] = busNumber;
      if (route != null) data['route'] = route;
      if (departureTime != null) data['departure_time'] = departureTime.toIso8601String();
      if (arrivalTime != null) data['arrival_time'] = arrivalTime.toIso8601String();
      if (totalSeats != null) data['total_seats'] = totalSeats;
      if (price != null) data['price'] = price;
      
      final response = await _dio.put('/buses/$busId', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteBus(int busId) async {
    try {
      await _dio.delete('/buses/$busId');
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== RÉSERVATIONS - GESTION =====
  
  Future<List<Map<String, dynamic>>> getReservations({
    int? page,
    int? limit,
    String? status,
    int? busId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status; // pending, confirmed, cancelled
      if (busId != null) queryParams['bus_id'] = busId;
      
      final response = await _dio.get('/reservations', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['reservations']);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getReservationById(int reservationId) async {
    try {
      final response = await _dio.get('/reservations/$reservationId');
      return response.data['reservation'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> cancelReservation(int reservationId) async {
    try {
      await _dio.delete('/reservations/$reservationId');
    } catch (e) {
      rethrow;
    }
  }
  
  // NOTE: l'API actuelle n'expose pas d'endpoint dédié au remboursement
  // (ex. POST /reservations/:id/refund). Les remboursements sont gérés
  // via la table `payments` côté serveur. Implémenter ici un appel vers
  // l'endpoint approprié lorsque le serveur le supportera.
  Future<Map<String, dynamic>> refundReservation({
    required int reservationId,
    String? reason,
  }) async {
    throw UnimplementedError('Refund endpoint not implemented on server');
  }
  
  // ===== EMPLOYÉS - GESTION =====
  
    // NOTE: Le serveur sépare la création d'un utilisateur (inscription)
    // et l'assignation d'un employé à un bus.
    // - Créer un compte employé: POST `/auth/register` (role: 'employee')
    // - Assigner un employé à un bus: POST `/employees` (user_id, bus_id)
    // - Lister les assignations: GET `/employees`
    // - Supprimer une assignation: DELETE `/employees/:id`
    // - Mettre à jour les données utilisateur: PUT `/users/:id`

    Future<List<Map<String, dynamic>>> getEmployees({int? page, int? limit}) async {
      try {
        final queryParams = <String, dynamic>{};
        if (page != null) queryParams['page'] = page;
        if (limit != null) queryParams['limit'] = limit;

        final response = await _dio.get('/employees', queryParameters: queryParams);
        return List<Map<String, dynamic>>.from(response.data['employees']);
      } catch (e) {
        rethrow;
      }
    }

    // Créer un utilisateur employé (inscription) -> utilise /auth/register
    Future<Map<String, dynamic>> createEmployeeUser({
      required String name,
      required String email,
      required String phone,
      required String password,
      String role = 'employee',
    }) async {
      try {
        final response = await _dio.post('/auth/register', data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
        });
        return response.data;
      } catch (e) {
        rethrow;
      }
    }

    // Mettre à jour les données d'un utilisateur (utiliser /users/:id)
    Future<Map<String, dynamic>> updateEmployeeUser({
      required int userId,
      String? name,
      String? phone,
      double? walletBalance, // si admin veut modifier
    }) async {
      try {
        final data = <String, dynamic>{};
        if (name != null) data['name'] = name;
        if (phone != null) data['phone'] = phone;
        if (walletBalance != null) data['wallet_balance'] = walletBalance;

        final response = await _dio.put('/users/$userId', data: data);
        return response.data;
      } catch (e) {
        rethrow;
      }
    }

    // Supprimer un utilisateur (admin): DELETE /users/:id
    // Supprimer une assignation d'employé à un bus: DELETE /employees/:id
    Future<void> deleteEmployeeUser(int userId) async {
      try {
        await _dio.delete('/users/$userId');
      } catch (e) {
        rethrow;
      }
    }

    // Assigner un utilisateur employé à un bus (création d'une assignation)
    Future<Map<String, dynamic>> assignEmployeeToBus({
      required int userId,
      required int busId,
    }) async {
      try {
        final response = await _dio.post('/employees', data: {
          'user_id': userId,
          'bus_id': busId,
        });
        return response.data;
      } catch (e) {
        rethrow;
      }
    }

    // ===== EXEMPLES FLUTTER - EMPLOYÉS =====

    // Exemple d'utilisation côté Flutter :
    // 1) Créer un utilisateur employé (inscription)
    // 2) Assigner l'utilisateur au bus
    // 3) Connexion employé via /auth/employee-login

    // Exemple : création + assignation (Admin)
    // Usage simplifié depuis un ViewModel ou un bouton d'admin
    Future<void> createAndAssignEmployeeExample() async {
      // 1) Créer l'utilisateur employé
      final newUser = await createEmployeeUser(
        name: 'Jean Dupont',
        email: 'jean.dupont@example.com',
        phone: '+22960000000',
        password: 'SecureP@ss123',
      );

      final createdUserId = newUser['user'] != null ? newUser['user']['id'] as int : int.parse(newUser['id'].toString());

      // 2) Assigner l'utilisateur au bus (admin doit être authentifié)
      final assignment = await assignEmployeeToBus(userId: createdUserId, busId: 12);

      // 3) (Optionnel) afficher résultat
      print('Utilisateur créé: $createdUserId');
      print('Assignation: $assignment');
    }

    // Exemple : login employé (par application employé)
    // Appelle POST /auth/employee-login avec employee_id et bus_id
    Future<Map<String, dynamic>> employeeLoginExample({
      required int employeeIdentifier, // peut être assignment id (e.id) ou user id (u.id)
      required int busId,
    }) async {
      try {
        final response = await _dio.post('/auth/employee-login', data: {
          'employee_id': employeeIdentifier,
          'bus_id': busId,
        });

        // L'API retourne `token`, `user` et `employee_assignment`
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('employee_jwt_token', response.data['token']);
        await prefs.setString('employee_id', response.data['user']['id'].toString());

        return response.data;
      } catch (e) {
        rethrow;
      }
    }

    // Exemple rapide (flux employé) :
    //  - L'employé ouvre l'app, indique son employee_id (assignment id ou user id) et bus_id
    //  - Appelle `employeeLoginExample(employeeIdentifier: 45, busId: 12)`
    //  - Stocke le token et utilise-le pour actions spécifiques à l'employé

  
  // ===== PAIEMENTS - CONSULTATION =====
  
  Future<List<Map<String, dynamic>>> getPayments({
    int? page,
    int? limit,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status; // pending, completed, failed
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      
      final response = await _dio.get('/payments', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['payments']);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getPaymentById(int paymentId) async {
    try {
      final response = await _dio.get('/payments/$paymentId');
      return response.data['payment'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> refundPayment({
    required int paymentId,
    String? reason,
  }) async {
    // L'API actuelle ne propose pas d'endpoint POST /payments/:id/refund.
    // Les remboursements sont enregistrés dans la table `payments` côté serveur.
    throw UnimplementedError('Payment refund endpoint not implemented on server');
  }
  
  // ===== UTILISATEURS - GESTION =====
  
  Future<List<Map<String, dynamic>>> getUsers({int? page, int? limit}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      
      final response = await _dio.get('/users', queryParameters: queryParams);
      return List<Map<String, dynamic>>.from(response.data['users']);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return response.data['user'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> deleteUser(int userId) async {
    try {
      await _dio.delete('/users/$userId');
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateUserWallet({
    required int userId,
    required double amount,
    required String action, // add, subtract
  }) async {
    try {
      final response = await _dio.post('/users/$userId/wallet', data: {
        'amount': amount,
        'action': action,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== STATISTIQUES & RAPPORTS =====
  
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // L'API n'expose pas d'endpoint unique '/admin/dashboard'.
      // Nous utilisons les statistiques de paiements comme source principale.
      final response = await _dio.get('/payments/stats/summary');
      return response.data; // { revenue: {...}, transactions: {...} }
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getRevenueStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // L'API expose `/payments/stats/summary` qui contient les revenus.
      final response = await _dio.get('/payments/stats/summary');
      return List<Map<String, dynamic>>.from(response.data['revenue'] ?? []);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getOccupancyStats({int? busId}) async {
    try {
      // L'API ne fournit pas d'endpoint `/admin/occupancy`.
      // Nous récupérons les réservations et les bus, puis calculons l'occupation.
      final reservationsResp = await _dio.get('/reservations');
      final busesResp = await _dio.get('/buses');

      final reservations = List<Map<String, dynamic>>.from(reservationsResp.data['reservations'] ?? []);
      final buses = List<Map<String, dynamic>>.from(busesResp.data['buses'] ?? []);

      if (busId != null) {
        final bus = buses.firstWhere((b) => b['id'] == busId, orElse: () => {});
        final totalSeats = bus['total_seats'] ?? 0;
        final booked = reservations.where((r) => r['bus_id'] == busId && r['status'] != 'cancelled').length;
        final occupancyRate = totalSeats > 0 ? (booked / totalSeats * 100) : 0;
        return [
          {
            'bus_id': busId,
            'total_seats': totalSeats,
            'booked': booked,
            'occupancy_rate': occupancyRate
          }
        ];
      }

      // Pour tous les bus
      return buses.map((b) {
        final id = b['id'];
        final totalSeats = b['total_seats'] ?? 0;
        final booked = reservations.where((r) => r['bus_id'] == id && r['status'] != 'cancelled').length;
        final occupancyRate = totalSeats > 0 ? (booked / totalSeats * 100) : 0;
        return {
          'bus_id': id,
          'total_seats': totalSeats,
          'booked': booked,
          'occupancy_rate': occupancyRate
        };
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getAdminProfile(int adminId) async {
    try {
      final response = await _dio.get('/users/$adminId');
      return response.data['user'];
    } catch (e) {
      rethrow;
    }
  }
}
```

---

## 3. STATE MANAGEMENT ADMIN AVEC PROVIDER

### A. Model Admin (lib/models/admin_model.dart)

```dart
class Admin {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final String role; // admin
  final DateTime createdAt;
  
  Admin({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.createdAt,
  });
  
  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    );
  }
}
```

### B. Model Employé (lib/models/employee_model.dart)

```dart
class Employee {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String position;
  final bool active;
  final int? assignedBusId;
  final DateTime createdAt;
  
  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.position,
    required this.active,
    this.assignedBusId,
    required this.createdAt,
  });
  
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      position: json['position'] as String,
      active: json['active'] as bool? ?? true,
      assignedBusId: json['assigned_bus_id'] as int?,
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    );
  }
}
```

### C. Provider Admin Auth (lib/providers/admin_auth_provider.dart)

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthProvider extends ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  
  Admin? _admin;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  
  Admin? get admin => _admin;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _admin != null;
  
  Future<void> adminLogin({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.adminLogin(
        email: email,
        password: password,
      );
      
      _token = response['token'];
      // L'endpoint `/auth/login` retourne l'utilisateur dans `user`
      _admin = Admin.fromJson(response['user']);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _admin = null;
      _token = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> adminLogout() async {
    await _apiService.adminLogout();
    _admin = null;
    _token = null;
    notifyListeners();
  }
  
  Future<void> checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_jwt_token');
    notifyListeners();
  }
}
```

### D. Provider Bus Admin (lib/providers/bus_admin_provider.dart)

```dart
import 'package:flutter/foundation.dart';

class BusAdminProvider extends ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  
  List<Map<String, dynamic>> _buses = [];
  bool _isLoading = false;
  String? _error;
  
  List<Map<String, dynamic>> get buses => _buses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchBuses({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _buses = await _apiService.getBuses(page: page, limit: limit);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>> createBus({
    required String busNumber,
    required String route,
    required DateTime departureTime,
    required DateTime arrivalTime,
    required int totalSeats,
    required double price,
  }) async {
    try {
      final result = await _apiService.createBus(
        busNumber: busNumber,
        route: route,
        departureTime: departureTime,
        arrivalTime: arrivalTime,
        totalSeats: totalSeats,
        price: price,
      );
      await fetchBuses();
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateBus({
    required int busId,
    String? busNumber,
    String? route,
    DateTime? departureTime,
    DateTime? arrivalTime,
    int? totalSeats,
    double? price,
  }) async {
    try {
      final result = await _apiService.updateBus(
        busId: busId,
        busNumber: busNumber,
        route: route,
        departureTime: departureTime,
        arrivalTime: arrivalTime,
        totalSeats: totalSeats,
        price: price,
      );
      await fetchBuses();
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
  
  Future<void> deleteBus(int busId) async {
    try {
      await _apiService.deleteBus(busId);
      await fetchBuses();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}
```

### E. Provider Employés (lib/providers/employee_provider.dart)

```dart
import 'package:flutter/foundation.dart';

class EmployeeProvider extends ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  
  List<Employee> _employees = [];
  bool _isLoading = false;
  String? _error;
  
  List<Employee> get employees => _employees;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchEmployees({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _apiService.getEmployees(page: page, limit: limit);
      _employees = data.map((e) => Employee.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>> createEmployee({
    required String name,
    required String email,
    required String phone,
    required String position,
    required String password,
  }) async {
    try {
      final result = await _apiService.createEmployee(
        name: name,
        email: email,
        phone: phone,
        position: position,
        password: password,
      );
      await fetchEmployees();
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
  
  Future<void> deleteEmployee(int employeeId) async {
    try {
      await _apiService.deleteEmployee(employeeId);
      await fetchEmployees();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
  
  Future<void> assignEmployeeToBus({
    required int employeeId,
    required int busId,
  }) async {
    try {
      await _apiService.assignEmployeeToBus(
        employeeId: employeeId,
        busId: busId,
      );
      await fetchEmployees();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}
```

### F. Provider Réservations Admin (lib/providers/reservation_admin_provider.dart)

```dart
import 'package:flutter/foundation.dart';

class ReservationAdminProvider extends ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = false;
  String? _error;
  
  List<Map<String, dynamic>> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchReservations({
    int page = 1,
    int limit = 20,
    String? status,
    int? busId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _reservations = await _apiService.getReservations(
        page: page,
        limit: limit,
        status: status,
        busId: busId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> cancelReservation(int reservationId) async {
    try {
      await _apiService.cancelReservation(reservationId);
      await fetchReservations();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> refundReservation({
    required int reservationId,
    String? reason,
  }) async {
    try {
      final result = await _apiService.refundReservation(
        reservationId: reservationId,
        reason: reason,
      );
      await fetchReservations();
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }
}
```

### G. Provider Statistiques (lib/providers/admin_stats_provider.dart)

```dart
import 'package:flutter/foundation.dart';

class AdminStatsProvider extends ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  
  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _revenueStats = [];
  List<Map<String, dynamic>> _occupancyStats = [];
  bool _isLoading = false;
  String? _error;
  
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> get revenueStats => _revenueStats;
  List<Map<String, dynamic>> get occupancyStats => _occupancyStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _dashboardStats = await _apiService.getDashboardStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchRevenueStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _revenueStats = await _apiService.getRevenueStats(
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchOccupancyStats({int? busId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _occupancyStats = await _apiService.getOccupancyStats(busId: busId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## 4. ÉCRANS ADMIN FLUTTER

### A. Écran de connexion Admin (lib/screens/admin/admin_login_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';

class AdminLoginScreen extends StatefulWidget {
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  void _handleAdminLogin() {
    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    
    authProvider.adminLogin(
      email: _emailController.text,
      password: _passwordController.text,
    ).then((_) {
      if (authProvider.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'Erreur de connexion')),
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🔐 Connexion Admin')),
      body: Consumer<AdminAuthProvider>(
        builder: (context, authProvider, _) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
                SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Admin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleAdminLogin,
                  child: authProvider.isLoading
                    ? CircularProgressIndicator()
                    : Text('Se connecter'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

### B. Écran Tableau de bord Admin (lib/screens/admin/admin_dashboard.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_stats_provider.dart';

class AdminDashboard extends StatefulWidget {
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    Provider.of<AdminStatsProvider>(context, listen: false).fetchDashboardStats();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('📊 Tableau de bord')),
      body: Consumer<AdminStatsProvider>(
        builder: (context, statsProvider, _) {
          if (statsProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (statsProvider.error != null) {
            return Center(child: Text('Erreur: ${statsProvider.error}'));
          }
          
          final stats = statsProvider.dashboardStats;
          
          return GridView.count(
            crossAxisCount: 2,
            padding: EdgeInsets.all(16),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatCard(
                title: 'Réservations',
                value: '${stats['total_reservations'] ?? 0}',
                icon: Icons.receipt,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Revenus',
                value: '${stats['total_revenue'] ?? 0} FCFA',
                icon: Icons.monetization_on,
                color: Colors.green,
              ),
              _buildStatCard(
                title: 'Bus Actifs',
                value: '${stats['active_buses'] ?? 0}',
                icon: Icons.directions_bus,
                color: Colors.orange,
              ),
              _buildStatCard(
                title: 'Utilisateurs',
                value: '${stats['total_users'] ?? 0}',
                icon: Icons.people,
                color: Colors.purple,
              ),
            ],
          );
        },
      ),
      drawer: AdminDrawer(),
    );
  }
  
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Panel Admin', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ListTile(
            leading: Icon(Icons.directions_bus),
            title: Text('🚌 Gestion Bus'),
            onTap: () => Navigator.pushNamed(context, '/admin/buses'),
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('👥 Employés'),
            onTap: () => Navigator.pushNamed(context, '/admin/employees'),
          ),
          ListTile(
            leading: Icon(Icons.receipt),
            title: Text('📋 Réservations'),
            onTap: () => Navigator.pushNamed(context, '/admin/reservations'),
          ),
          ListTile(
            leading: Icon(Icons.payment),
            title: Text('💳 Paiements'),
            onTap: () => Navigator.pushNamed(context, '/admin/payments'),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('👤 Utilisateurs'),
            onTap: () => Navigator.pushNamed(context, '/admin/users'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Déconnexion'),
            onTap: () {
              Provider.of<AdminAuthProvider>(context, listen: false).adminLogout();
              Navigator.pushReplacementNamed(context, '/admin-login');
            },
          ),
        ],
      ),
    );
  }
}
```

### C. Écran Gestion des Bus (lib/screens/admin/buses_management_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bus_admin_provider.dart';
import 'package:intl/intl.dart';

class BusesManagementScreen extends StatefulWidget {
  @override
  State<BusesManagementScreen> createState() => _BusesManagementScreenState();
}

class _BusesManagementScreenState extends State<BusesManagementScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<BusAdminProvider>(context, listen: false).fetchBuses();
  }
  
  void _showCreateBusDialog() {
    final form = GlobalKey<FormState>();
    String busNumber = '';
    String route = '';
    DateTime departureTime = DateTime.now();
    DateTime arrivalTime = DateTime.now().add(Duration(hours: 5));
    int totalSeats = 50;
    double price = 10000;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un bus'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Numéro du bus'),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  onSaved: (v) => busNumber = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Route'),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  onSaved: (v) => route = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nombre de places'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  onSaved: (v) => totalSeats = int.parse(v!),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Prix (FCFA)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  onSaved: (v) => price = double.parse(v!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                form.currentState!.save();
                Provider.of<BusAdminProvider>(context, listen: false).createBus(
                  busNumber: busNumber,
                  route: route,
                  departureTime: departureTime,
                  arrivalTime: arrivalTime,
                  totalSeats: totalSeats,
                  price: price,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bus créé avec succès!')),
                );
              }
            },
            child: Text('Créer'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🚌 Gestion des Bus')),
      body: Consumer<BusAdminProvider>(
        builder: (context, busProvider, _) {
          if (busProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (busProvider.error != null) {
            return Center(child: Text('Erreur: ${busProvider.error}'));
          }
          
          return ListView.builder(
            itemCount: busProvider.buses.length,
            itemBuilder: (context, index) {
              final bus = busProvider.buses[index];
              final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
              
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${bus['bus_number']} - ${bus['route']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Départ: ${dateFormat.format(DateTime.parse(bus['departure_time']))}'),
                      Text('Places: ${bus['available_seats']}/${bus['total_seats']}'),
                      Text('Prix: ${bus['price'].toStringAsFixed(0)} FCFA'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Text('Modifier'),
                        onTap: () => _showEditBusDialog(bus),
                      ),
                      PopupMenuItem(
                        child: Text('Supprimer'),
                        onTap: () => busProvider.deleteBus(bus['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBusDialog,
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _showEditBusDialog(Map<String, dynamic> bus) {
    // Implémentation similaire à _showCreateBusDialog
  }
}
```

### D. Écran Gestion des Employés (lib/screens/admin/employees_management_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/employee_model.dart';

class EmployeeManagementScreen extends StatefulWidget {
  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees();
  }
  
  void _showCreateEmployeeDialog() {
    final form = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';
    String position = 'Conducteur';
    String password = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un employé'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nom'),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  onSaved: (v) => name = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  onSaved: (v) => email = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Téléphone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  onSaved: (v) => phone = v!,
                ),
                DropdownButtonFormField(
                  value: position,
                  items: ['Conducteur', 'Agent', 'Superviseur']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                  onChanged: (v) => position = v!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  onSaved: (v) => password = v!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                form.currentState!.save();
                Provider.of<EmployeeProvider>(context, listen: false).createEmployee(
                  name: name,
                  email: email,
                  phone: phone,
                  position: position,
                  password: password,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Employé créé avec succès!')),
                );
              }
            },
            child: Text('Créer'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('👥 Gestion des Employés')),
      body: Consumer<EmployeeProvider>(
        builder: (context, employeeProvider, _) {
          if (employeeProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (employeeProvider.error != null) {
            return Center(child: Text('Erreur: ${employeeProvider.error}'));
          }
          
          return ListView.builder(
            itemCount: employeeProvider.employees.length,
            itemBuilder: (context, index) {
              final employee = employeeProvider.employees[index];
              
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(employee.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${employee.email}'),
                      Text('Position: ${employee.position}'),
                      Text('Téléphone: ${employee.phone}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Text('Modifier'),
                        onTap: () => _showEditEmployeeDialog(employee),
                      ),
                      PopupMenuItem(
                        child: Text('Supprimer'),
                        onTap: () => employeeProvider.deleteEmployee(employee.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEmployeeDialog,
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _showEditEmployeeDialog(Employee employee) {
    // Implémentation similaire à _showCreateEmployeeDialog
  }
}
```

---

## 5. MAIN.DART ADMIN - Configuration initiale

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/admin_auth_provider.dart';
import 'providers/bus_admin_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/reservation_admin_provider.dart';
import 'providers/admin_stats_provider.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/buses_management_screen.dart';
import 'screens/admin/employees_management_screen.dart';

void main() async {
  runApp(MyAdminApp());
}

class MyAdminApp extends StatefulWidget {
  @override
  State<MyAdminApp> createState() => _MyAdminAppState();
}

class _MyAdminAppState extends State<MyAdminApp> {
  @override
  void initState() {
    super.initState();
    Provider.of<AdminAuthProvider>(context, listen: false).checkToken();
  }
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => BusAdminProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ReservationAdminProvider()),
        ChangeNotifierProvider(create: (_) => AdminStatsProvider()),
      ],
      child: MaterialApp(
        title: 'Bus Admin',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Consumer<AdminAuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.isLoggedIn 
              ? AdminDashboard()
              : AdminLoginScreen();
          },
        ),
        routes: {
          '/admin-login': (_) => AdminLoginScreen(),
          '/admin-dashboard': (_) => AdminDashboard(),
          '/admin/buses': (_) => BusesManagementScreen(),
          '/admin/employees': (_) => EmployeeManagementScreen(),
        },
      ),
    );
  }
}
```

---

## 6. GESTION DES PAIEMENTS & REVENUS

```dart
class PaymentsManagementScreen extends StatefulWidget {
  @override
  State<PaymentsManagementScreen> createState() => _PaymentsManagementScreenState();
}

class _PaymentsManagementScreenState extends State<PaymentsManagementScreen> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AdminStatsProvider>(context, listen: false);
    provider.fetchRevenueStats();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('💳 Gestion des Paiements')),
      body: Consumer<AdminStatsProvider>(
        builder: (context, statsProvider, _) {
          if (statsProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            itemCount: statsProvider.revenueStats.length,
            itemBuilder: (context, index) {
              final payment = statsProvider.revenueStats[index];
              
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${payment['bus_number']} - ${payment['date']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Montant: ${payment['amount']} FCFA'),
                      Text('Réservations: ${payment['reservation_count']}'),
                    ],
                  ),
                  trailing: Text(
                    '${payment['occupancy_rate']}%',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 7. NOTIFICATIONS & ALERTES ADMIN

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@app_icon');
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'admin_channel',
      'Admin Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
```

---

## 8. POINTS IMPORTANTS POUR FLUTTER ADMIN

✅ **À faire:**
- Stocker le JWT token admin en securité avec `flutter_secure_storage`
- Implémenter la pagination pour les listes de réservations/paiements
- Ajouter des filtres (par date, par bus, par statut)
- Mettre en place des graphiques pour les statistiques
- Implémenter les notifications pour les événements importants
- Valider les formulaires côté client
- Mettre à jour l'URL API pour la production

⚠️ **À vérifier:**
- Les permissions admin sur les endpoints
- Formats de données cohérents avec l'API
- Gestion des timezones pour les rapports
- Sécurité des données sensibles

🔒 **Sécurité:**
```dart
// Utiliser flutter_secure_storage pour le token admin
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
await storage.write(key: 'admin_jwt_token', value: token);
```

---

## 9. CONFIGURATION ANDROID & iOS (ADMIN)

### Android (android/app/build.gradle)
```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS (ios/Podfile)
```
<key>NSLocalNetworkUsageDescription</key>
<string>Nous avons besoin d'accès au réseau local</string>
```

---

## 10. REDIRECTION AUTO LOGIN/DASHBOARD (SESSION ADMIN)

### A. Endpoint API utilisé

`GET /api/auth/me` avec header `Authorization: Bearer <token>`

### B. Mise à jour `AdminAuthProvider`

```dart
class AdminAuthProvider extends ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();

  Admin? _admin;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  Admin? get admin => _admin;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _admin != null;

  Future<void> initializeSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('admin_jwt_token');

      if (_token == null) {
        _admin = null;
      } else {
        final result = await _apiService.getAdminProfile(
          int.parse(prefs.getString('admin_id') ?? '0'),
        );
        _admin = Admin.fromJson(result);
      }
    } catch (_) {
      await _apiService.adminLogout();
      _token = null;
      _admin = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }
}
```

### C. Créer un `AdminAuthGate`

```dart
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized || auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return auth.isLoggedIn ? AdminDashboard() : AdminLoginScreen();
      },
    );
  }
}
```

---

## 11. TEST AVEC POSTMAN PUIS FLUTTER ADMIN

1. **Tester l'API d'abord avec Postman** (endpoints admin)
2. **Adapter l'URL de base** pour correspondre à votre environnement
3. **Importer dans Flutter** et tester chaque endpoint admin
4. **Vérifier les réponses JSON** qu'elles matchent avec les models admin
5. **Déployer en production** quand tout fonctionne

---

**Besoin d'aide pour une partie spécifique ? 🚀 Posez vos questions!**

