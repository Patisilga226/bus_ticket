# 📱 Guide d'Intégration de l'API dans Flutter

## 1. SETUP INITIAL FLUTTER

### A. Dépendances requises (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0              # Pour les requêtes HTTP
  dio: ^5.3.0               # Alternative robuste à http
  provider: ^6.0.0          # State management
  shared_preferences: ^2.2.0 # Stockage local (tokens)
  qr_code_scanner: ^2.0.0   # Scanner QR
  qr_flutter: ^4.0.0        # Génération QR
  intl: ^0.19.0             # Formatage dates/devises

dev_dependencies:
  flutter_test:
    sdk: flutter
```

Installez les dépendances:
```bash
flutter pub get
```

---

## 2. CONFIGURATION DE LA CONNEXION API

### A. Créer un service HTTP (lib/services/api_service.dart)

```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  // En production: https://votre-api.com/api
  
  late Dio _dio;
  
  ApiService() {
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
    
    // Interceptor pour ajouter le token JWT
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
        onError: (error, handler) {
          // Gestion des erreurs globales
          if (error.response?.statusCode == 401) {
            // Token expiré, rediriger vers login
            print('Token expiré');
          }
          return handler.next(error);
        },
      ),
    );
  }
  
  // ===== AUTHENTIFICATION =====
  
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      // Sauvegarder le token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', response.data['token']);
      await prefs.setString('user_id', response.data['user']['id'].toString());
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
  }
  
  // ===== BUS =====
  
  Future<List<Map<String, dynamic>>> getBuses() async {
    try {
      final response = await _dio.get('/buses');
      return List<Map<String, dynamic>>.from(response.data['buses']);
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getBusById(int busId) async {
    try {
      final response = await _dio.get('/buses/$busId');
      return response.data['bus'];
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== RÉSERVATIONS =====
  
  Future<Map<String, dynamic>> createReservation({
    required int busId,
    int? seatNumber,
  }) async {
    try {
      final response = await _dio.post('/reservations', data: {
        'bus_id': busId,
        'seat_number': seatNumber,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getReservations() async {
    try {
      final response = await _dio.get('/reservations');
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
  
  // ===== PAIEMENTS =====
  
  Future<List<Map<String, dynamic>>> getPayments() async {
    try {
      final response = await _dio.get('/payments');
      return List<Map<String, dynamic>>.from(response.data['payments']);
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== SCAN QR =====
  
  Future<Map<String, dynamic>> scanQrCode(String qrCode) async {
    try {
      final response = await _dio.post('/scan-qr', data: {
        'qr_code': qrCode,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // ===== UTILISATEUR =====
  
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return response.data['user'];
    } catch (e) {
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    String? name,
    String? phone,
  }) async {
    try {
      final response = await _dio.put('/users/$userId', data: {
        'name': name,
        'phone': phone,
      });
      return response.data['user'];
    } catch (e) {
      rethrow;
    }
  }
}
```

---

## 3. STATE MANAGEMENT AVEC PROVIDER

### A. Model utilisateur (lib/models/user_model.dart)

```dart
class User {
  final int id;
  final String email;
  final String name;
  final String? phone;
  final String role;
  final double walletBalance;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.walletBalance,
    required this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      walletBalance: json['wallet_balance'] != null 
        ? double.parse(json['wallet_balance'].toString()) 
        : 0.0,
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    );
  }
}
```

### B. Model Bus (lib/models/bus_model.dart)

```dart
class Bus {
  final int id;
  final String busNumber;
  final String route;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int totalSeats;
  final int availableSeats;
  final double price;
  
  Bus({
    required this.id,
    required this.busNumber,
    required this.route,
    required this.departureTime,
    required this.arrivalTime,
    required this.totalSeats,
    required this.availableSeats,
    required this.price,
  });
  
  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as int,
      busNumber: json['bus_number'] as String,
      route: json['route'] as String,
      departureTime: DateTime.parse(json['departure_time'] as String),
      arrivalTime: DateTime.parse(json['arrival_time'] as String),
      totalSeats: json['total_seats'] as int,
      availableSeats: json['available_seats'] as int,
      price: double.parse(json['price'].toString()),
    );
  }
}
```

### C. Provider pour l'authentification (lib/providers/auth_provider.dart)

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _user != null;
  
  Future<void> initializeSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('jwt_token');

      if (_token == null) {
        _user = null;
      } else {
        final result = await _apiService.getCurrentUser();
        _user = User.fromJson(result['user']);
      }
    } catch (_) {
      // Token expire / invalide => deconnexion locale
      await _apiService.logout();
      _token = null;
      _user = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }
}
```

### D. Provider pour les bus (lib/providers/bus_provider.dart)

```dart
import 'package:flutter/foundation.dart';

class BusProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Bus> _buses = [];
  bool _isLoading = false;
  String? _error;
  
  List<Bus> get buses => _buses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchBuses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final busesData = await _apiService.getBuses();
      _buses = busesData.map((bus) => Bus.fromJson(bus)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Filtrer par route
  List<Bus> filterByRoute(String route) {
    return _buses.where((bus) => bus.route.toLowerCase().contains(route.toLowerCase())).toList();
  }
  
  // Filtrer par date
  List<Bus> filterByDate(DateTime date) {
    return _buses.where((bus) => 
      bus.departureTime.year == date.year &&
      bus.departureTime.month == date.month &&
      bus.departureTime.day == date.day
    ).toList();
  }
}
```

### E. Provider pour les réservations (lib/providers/reservation_provider.dart)

```dart
import 'package:flutter/foundation.dart';

class ReservationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = false;
  String? _error;
  
  List<Map<String, dynamic>> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchReservations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _reservations = await _apiService.getReservations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>> createReservation({
    required int busId,
    int? seatNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _apiService.createReservation(
        busId: busId,
        seatNumber: seatNumber,
      );
      await fetchReservations(); // Rafraîchir la liste
      return result;
    } catch (e) {
      _error = e.toString();
      rethrow;
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
}
```

---

## 4. ÉCRANS FLUTTER

### A. Écran de connexion (lib/screens/login_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  void _handleLogin() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
    ).then((_) {
      if (authProvider.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
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
      appBar: AppBar(title: Text('Connexion')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleLogin,
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

### B. Écran liste des bus (lib/screens/buses_list_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/bus_provider.dart';

class BusesListScreen extends StatefulWidget {
  @override
  State<BusesListScreen> createState() => _BusesListScreenState();
}

class _BusesListScreenState extends State<BusesListScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les bus au démarrage
    Provider.of<BusProvider>(context, listen: false).fetchBuses();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🚌 Réserver un bus')),
      body: Consumer<BusProvider>(
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
                  title: Text('${bus.busNumber} - ${bus.route}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Départ: ${dateFormat.format(bus.departureTime)}'),
                      Text('Places: ${bus.availableSeats}/${bus.totalSeats}'),
                      Text('Prix: ${bus.price.toStringAsFixed(0)} FCFA'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/reservation-details',
                        arguments: bus,
                      );
                    },
                    child: Text('Réserver'),
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

### C. Écran de réservation (lib/screens/reservation_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reservation_provider.dart';
import '../models/bus_model.dart';

class ReservationScreen extends StatefulWidget {
  final Bus bus;
  
  ReservationScreen({required this.bus});
  
  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  int? _selectedSeat;
  
  void _handleReservation() {
    final reservationProvider = 
      Provider.of<ReservationProvider>(context, listen: false);
    
    reservationProvider.createReservation(
      busId: widget.bus.id,
      seatNumber: _selectedSeat,
    ).then((result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation réussie!')),
      );
      // Afficher le QR code
      _showQrCode(result['qr_code']);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error')),
      );
    });
  }
  
  void _showQrCode(String qrCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Votre QR Code'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Afficher le QR code (nécessite qr_flutter)
              Image.network(qrCode),
              SizedBox(height: 16),
              Text('Montrez ce code au bus'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Réservation')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.bus.busNumber} - ${widget.bus.route}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            Text('Sélectionner un siège:'),
            SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
              ),
              itemCount: widget.bus.totalSeats,
              itemBuilder: (context, index) {
                final seatNumber = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSeat = seatNumber);
                  },
                  child: Card(
                    color: _selectedSeat == seatNumber 
                      ? Colors.blue 
                      : Colors.grey[200],
                    child: Center(
                      child: Text('$seatNumber'),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Text('Prix: ${widget.bus.price.toStringAsFixed(0)} FCFA'),
            SizedBox(height: 10),
            Text('Caution: 100 FCFA'),
            SizedBox(height: 10),
            Text(
              'Total: ${(widget.bus.price + 100).toStringAsFixed(0)} FCFA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedSeat != null ? _handleReservation : null,
              child: Text('Confirmer la réservation'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. MAIN.DART - Configuration initiale

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/bus_provider.dart';
import 'providers/reservation_provider.dart';
import 'screens/login_screen.dart';
import 'screens/buses_list_screen.dart';
import 'screens/reservation_screen.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Vérifier si l'utilisateur est déjà connecté
    Provider.of<AuthProvider>(context, listen: false).checkToken();
  }
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
      ],
      child: MaterialApp(
        title: 'Bus Reservation',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.isLoggedIn 
              ? BusesListScreen()
              : LoginScreen();
          },
        ),
        routes: {
          '/login': (_) => LoginScreen(),
          '/home': (_) => BusesListScreen(),
          '/reservation-details': (context) {
            final bus = ModalRoute.of(context)?.settings.arguments as Bus;
            return ReservationScreen(bus: bus);
          },
        },
      ),
    );
  }
}
```

---

## 6. GESTION DES QR CODES EN FLUTTER

### A. Scanner QR avec caméra

```dart
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  StreamSubscription? _scanSub;

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scanner un QR code')),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;

    // Cancel existing before subscribing
    _scanSub?.cancel();
    _scanSub = controller!.scannedDataStream.listen((scanData) async {
      final code = scanData.code;
      if (code == null || code.isEmpty) {
        controller?.resumeCamera();
        return;
      }

      controller?.pauseCamera();

      try {
        // Option A: utiliser ApiService directement
        final api = ApiService();
        final result = await api.scanQrCode(code);

        // Option B (si ApiService fourni via Provider):
        // final result = await Provider.of<ApiService>(context, listen: false).scanQrCode(code);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'OK')),
        );

        if (!mounted) return;
        Navigator.of(context).pop(result);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
        controller?.resumeCamera();
      }
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    controller?.dispose();
    super.dispose();
  }
}
```


### B. Récupérer et afficher le QR depuis l'API

L'API expose `GET /reservations/:id/qrcode` qui retourne un objet JSON contenant un `qr_code` au format Data URL (ex: `data:image/png;base64,...`) et `qr_valid_until`.

- Auth: le token JWT est envoyé automatiquement si vous utilisez l'`ApiService` avec l'interceptor présenté plus haut.
- Endpoint: `/reservations/<reservationId>/qrcode`

Exemple d'ajout dans `ApiService` (lib/services/api_service.dart) :

```dart
Future<String> getReservationQr(int reservationId) async {
  try {
    final response = await _dio.get('/reservations/$reservationId/qrcode');
    return response.data['qr_code'] as String; // data:image/png;base64,...
  } catch (e) {
    rethrow;
  }
}
```

Exemple rapide d'utilisation dans un widget Flutter :

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ReservationQrPage extends StatefulWidget {
  final int reservationId;
  const ReservationQrPage({required this.reservationId, super.key});

  @override
  State<ReservationQrPage> createState() => _ReservationQrPageState();
}

class _ReservationQrPageState extends State<ReservationQrPage> {
  Uint8List? _qrBytes;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    try {
      final api = ApiService(); // ou injecter via Provider
      final dataUrl = await api.getReservationQr(widget.reservationId);
      final parts = dataUrl.split(',');
      final base64Part = parts.length > 1 ? parts.sublist(1).join(',') : parts[0];
      final bytes = base64Decode(base64Part);
      setState(() { _qrBytes = bytes; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Réservation')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Text('Erreur: 
\$_error')
                : _qrBytes != null
                    ? Image.memory(_qrBytes!)
                    : const Text('Aucun QR disponible'),
      ),
    );
  }
}
```

Remarques:
- Assurez-vous d'utiliser `10.0.2.2` comme hôte pour accéder à `localhost` depuis l'émulateur Android.
- L'interceptor dans `ApiService` ajoute le header `Authorization: Bearer <token>` si le token est stocké.
- Vous pouvez aussi sauvegarder le Data URL et l'afficher via `Image.network(dataUrl)` si vous préférez éviter la décodage côté client.

---

### C. Login employé et affichage des passagers (Employee)

L'API propose un endpoint dédié pour les employés: `POST /employee-login` (body: `employee_id`, `bus_id`) qui retourne un token JWT contenant `bus_id` et `employee_assignment_id`. Une fois connecté, un employé peut obtenir la liste de ses passagers via `GET /scan-qr/clients` (params optionnels `status`, `bus_id`).

Ajout dans `ApiService` :

```dart
// Login employe
Future<Map<String, dynamic>> employeeLogin({
  required int employeeId,
  required int busId,
}) async {
  final response = await _dio.post('/employee-login', data: {
    'employee_id': employeeId,
    'bus_id': busId,
  });
  // Sauvegarder token
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('jwt_token', response.data['token']);
  return response.data;
}

// Recuperer les passagers (employe/admin)
Future<List<Map<String, dynamic>>> getClients({String status = 'all', int? busId}) async {
  final query = <String, dynamic>{};
  if (status != 'all') query['status'] = status;
  if (busId != null) query['bus_id'] = busId;
  final response = await _dio.get('/scan-qr/clients', queryParameters: query);
  return List<Map<String, dynamic>>.from(response.data['clients']);
}
```

Exemple de widget pour login employé :

```dart
class EmployeeLoginForm extends StatefulWidget {
  @override
  State<EmployeeLoginForm> createState() => _EmployeeLoginFormState();
}

class _EmployeeLoginFormState extends State<EmployeeLoginForm> {
  final _employeeIdCtl = TextEditingController();
  final _busIdCtl = TextEditingController();
  bool _loading = false;

  void _login() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final res = await api.employeeLogin(
        employeeId: int.parse(_employeeIdCtl.text),
        busId: int.parse(_busIdCtl.text),
      );
      // Naviguer vers la page des passagers
      Navigator.pushNamed(context, '/employee/clients');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _employeeIdCtl, decoration: InputDecoration(labelText: 'Employee ID')),
        TextField(controller: _busIdCtl, decoration: InputDecoration(labelText: 'Bus ID')),
        ElevatedButton(onPressed: _loading ? null : _login, child: _loading ? CircularProgressIndicator() : Text('Se connecter')),
      ],
    );
  }
}
```

Exemple d'écran pour afficher les passagers de l'employé :

```dart
class EmployeeClientsPage extends StatefulWidget {
  @override
  State<EmployeeClientsPage> createState() => _EmployeeClientsPageState();
}

class _EmployeeClientsPageState extends State<EmployeeClientsPage> {
  List<Map<String, dynamic>> _clients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final api = ApiService();
      final clients = await api.getClients();
      setState(() { _clients = clients; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Erreur: $_error'));
    return ListView.builder(
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final c = _clients[index];
        return ListTile(
          title: Text(c['client_name'] ?? 'Nom inconnu'),
          subtitle: Text('${c['bus_number'] ?? ''} • Siège ${c['seat_number'] ?? ''}'),
          trailing: Text(c['status'] ?? ''),
        );
      },
    );
  }
}
```

Notes:
- Le endpoint `GET /scan-qr/clients` accepte `status` (`all|pending|scanned|cancelled`) et `bus_id` en query params.
- Le token retourné par `/employee-login` contient `bus_id` : l'interceptor enverra automatiquement le header `Authorization`.
- Pour un employé connecté, l'API filtre automatiquement par bus assigné si nécessaire.

---

### D. Liste des codes QR valides de l'utilisateur

L'utilisateur possède un endpoint `GET /reservations` qui retourne toutes ses réservations triées par `created_at DESC` (plus récent d'abord). Chaque réservation contient un `qr_code` (Data URL) et `qr_valid_until` permettant de vérifier la validité.

Ajout dans `ApiService` :

```dart
// Recuperer les reservations utilisateur (avec tous les QR codes)
Future<List<Map<String, dynamic>>> getUserReservations() async {
  try {
    final response = await _dio.get('/reservations');
    return List<Map<String, dynamic>>.from(response.data['reservations']);
  } catch (e) {
    rethrow;
  }
}
```

Helper pour filtrer les QR codes valides:

```dart
class QrCodeHelper {
  static bool isQrValid(Map<String, dynamic> reservation) {
    final now = DateTime.now();
    final qrValidUntil = reservation['qr_valid_until'] != null
        ? DateTime.parse(reservation['qr_valid_until'] as String)
        : null;
    return qrValidUntil != null && now.isBefore(qrValidUntil);
  }

  static String formatDateTime(String? dateStr) {
    if (dateStr == null) return 'Date inconnue';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Format invalide';
    }
  }
}
```

Écran pour afficher la liste des codes QR:

```dart
class UserQrListPage extends StatefulWidget {
  @override
  State<UserQrListPage> createState() => _UserQrListPageState();
}

class _UserQrListPageState extends State<UserQrListPage> {
  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      final api = ApiService();
      final res = await api.getUserReservations();
      setState(() { _reservations = res; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showQrCode(Map<String, dynamic> reservation) {
    final dataUrl = reservation['qr_code'] as String?;
    if (dataUrl == null) return;
    
    final parts = dataUrl.split(',');
    final base64Part = parts.length > 1 ? parts.sublist(1).join(',') : parts[0];
    final bytes = base64Decode(base64Part);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${reservation['bus_number']} - ${reservation['route']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(bytes, width: 250, height: 250),
            SizedBox(height: 12),
            Text('Siège: ${reservation['seat_number']}'),
            Text('Valide jusqu\'à: ${QrCodeHelper.formatDateTime(reservation['qr_valid_until'])}'),
          ],
        ),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Fermer'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text('Erreur: $_error')));
    
    // Filtrer les QR valides et trier par date (plus récent d'abord)
    final validQrs = _reservations
        .where((r) => QrCodeHelper.isQrValid(r))
        .toList()
      ..sort((a, b) {
        final aDate = a['created_at'] != null ? DateTime.parse(a['created_at']) : DateTime(1970);
        final bDate = b['created_at'] != null ? DateTime.parse(b['created_at']) : DateTime(1970);
        return bDate.compareTo(aDate); // Plus récent d'abord
      });

    if (validQrs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes codes QR')),
        body: const Center(child: Text('Aucun code QR valide')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes codes QR')),
      body: ListView.builder(
        itemCount: validQrs.length,
        itemBuilder: (context, index) {
          final res = validQrs[index];
          final isValid = QrCodeHelper.isQrValid(res);
          return Card(
            margin: const EdgeInsets.all(8),
            color: isValid ? Colors.green.shade50 : Colors.grey.shade100,
            child: ListTile(
              title: Text('${res['bus_number']} - ${res['route']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Siège: ${res['seat_number']}'),
                  Text('Créée: ${QrCodeHelper.formatDateTime(res['created_at'])}'),
                  Text(
                    'Valide jusqu\'à: ${QrCodeHelper.formatDateTime(res['qr_valid_until'])}',
                    style: TextStyle(
                      color: isValid ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: isValid
                  ? ElevatedButton(
                      onPressed: () => _showQrCode(res),
                      child: const Text('Voir QR'),
                    )
                  : const Text('Expiré', style: TextStyle(color: Colors.red)),
            ),
          );
        },
      ),
    );
  }
}
```

Notes:
- L'endpoint `GET /reservations` retourne TOUTES les réservations triées par `created_at DESC` (le tri est déjà fait côté API).
- Utilisez `qr_valid_until` pour vérifier la validité d'un QR: s'il est dans le futur, le QR est valide.
- Vous pouvez filtrer au niveau de la liste pour afficher uniquement les QR valides avec `where()`.
- Le `qr_code` est un Data URL (format `data:image/png;base64,...`) facile à décoder et afficher en Flutter.

---

## 7. GESTION DES ERREURS & CONNECTIVITÉ

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> isConnected() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  static Stream<ConnectivityResult> onConnectivityChanged() {
    return Connectivity().onConnectivityChanged;
  }
}

// Usage dans un Provider:
Future<void> fetchBusesWithCheck() async {
  if (!await ConnectivityService.isConnected()) {
    _error = 'Pas de connexion internet';
    notifyListeners();
    return;
  }
  
  await fetchBuses();
}
```

---

## 8. POINTS IMPORTANTS POUR FLUTTER

✅ **À faire:**
- Stocker le JWT token en securité avec `flutter_secure_storage`
- Gérer la session utilisateur avec Provider/Riverpod
- Implémenter la pagination GET pour les listes longues
- Ajouter des loading states et error handling
- Tester les QR codes générés par l'API
- Valider les formulaires côté client
- Mettre à jour l'URL API pour la production

⚠️ **À vérifier:**
- Permissions caméra sur iOS/Android
- Configuration de base du serveur (URL correcte)
- Formats de dates/heures compatibles
- Gestion des timezones

🔒 **Sécurité:**
```dart
// Utiliser flutter_secure_storage au lieu de SharedPreferences pour le token
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();
await storage.write(key: 'jwt_token', value: token);
```

---

## 9. CONFIGURATION ANDROID & iOS

### Android (android/app/build.gradle)
```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21 // Pour les caméras
    }
}
```

### iOS (ios/Podfile)
Ajouter dans les permissions:
```
<key>NSCameraUsageDescription</key>
<string>Nous avons besoin de l'accès à la caméra pour scanner les QR codes</string>
```

---

## 10. REDIRECTION AUTO LOGIN/HOME (SESSION UTILISATEUR)

Ce flux valide le token sur le serveur (pas seulement sa présence en local).

### A. Endpoint API utilise

`GET /api/auth/me` avec header `Authorization: Bearer <token>`

### B. Ajouter dans `ApiService`

```dart
Future<Map<String, dynamic>> getCurrentUser() async {
  try {
    final response = await _dio.get('/auth/me');
    return Map<String, dynamic>.from(response.data);
  } catch (e) {
    rethrow;
  }
}
```

### C. Mettre a jour `AuthProvider`

```dart
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoggedIn => _token != null && _user != null;

  Future<void> initializeSession() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('jwt_token');

      if (_token == null) {
        _user = null;
      } else {
        final result = await _apiService.getCurrentUser();
        _user = User.fromJson(result['user']);
      }
    } catch (_) {
      // Token expire / invalide => deconnexion locale
      await _apiService.logout();
      _token = null;
      _user = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }
}
```

### D. Creer un `AuthGate` (nouveau widget)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'buses_list_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized || auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return auth.isLoggedIn ? BusesListScreen() : LoginScreen();
      },
    );
  }
}
```

### E. Mettre a jour `main.dart`

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initializeSession(),
        ),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
      ],
      child: MaterialApp(
        title: 'Bus Reservation',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthGate(),
        routes: {
          '/login': (_) => LoginScreen(),
          '/home': (_) => BusesListScreen(),
        },
      ),
    );
  }
}
```

Resultat: au lancement, si le token est valide l'utilisateur va sur l'accueil; sinon il est redirige vers la page de connexion.

---

## 11. TEST AVEC POSTMAN PUIS FLUTTER

1. **Tester l'API d'abord avec Postman** (déjà fourni)
2. **Adapter l'URL de base** pour correspondre à votre environnement
3. **Importer dans Flutter** et tester chaque endpoint
4. **Vérifier les réponses JSON** qu'elles matchent avec les models
5. **Déployer en production** quand tout fonctionne

---

**Besoin d'aide pour une partie spécifique ? Posez vos questions! 🚀**
