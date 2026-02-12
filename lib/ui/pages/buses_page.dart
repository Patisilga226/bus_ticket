import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:convert';
import '../../services/api_service.dart';
import '../../models/bus.dart';
import '../themes/dashboard_theme.dart';
import '../utils/responsive_layout.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({super.key});

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  List<Bus> _buses = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadBuses();
  }

  Future<void> _loadBuses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final busesData = await _apiService.getBuses();
      setState(() {
        _buses = busesData.map((data) => Bus.fromJson(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $_errorMessage')),
      );
    }
  }

  Future<void> _showAddBusDialog() async {
    final codeCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '50');
    String category = 'Standard';
    String status = 'Available';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        final isMobile = ResponsiveLayout.isMobile(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardTheme.radiusXl),
          ),
          title: Text(
            'Ajouter un bus',
            style: DashboardTheme.titleLarge.copyWith(
              color: DashboardTheme.onSurface,
            ),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: 24,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  TextFormField(
                    controller: codeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Code bus',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                      hintText: 'e.g., BUS-001',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Bus code is required';
                      }
                      if (v.length < 3) {
                        return 'Bus code must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: routeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Trajet principal',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Trajet obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: capacityCtrl,
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                      hintText: 'Number of seats',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Capacity is required';
                      }
                      final capacity = int.tryParse(v);
                      if (capacity == null || capacity <= 0) {
                        return 'Capacity must be a positive number';
                      }
                      if (capacity > 100) {
                        return 'Capacity cannot exceed 100 seats';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: 'Catégorie de bus',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                      DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                      DropdownMenuItem(value: 'Economy', child: Text('Économique')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => category = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Available', child: Text('Disponible')),
                      DropdownMenuItem(value: 'In Transit', child: Text('En route')),
                      DropdownMenuItem(value: 'Maintenance', child: Text('En maintenance')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => status = v);
                    },
                  ),
                ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: DashboardTheme.labelMedium.copyWith(
                  color: DashboardTheme.onSurfaceVariant,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop({
                  'busCode': codeCtrl.text.trim(),
                  'route': routeCtrl.text.trim(),
                  'category': category,
                  'status': status,
                  'capacity': int.parse(capacityCtrl.text),
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: DashboardTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                ),
              ),
              child: Text(
                'Ajouter',
                style: DashboardTheme.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Creating bus...'),
            backgroundColor: DashboardTheme.info,
          ),
        );
        
        final newBus = await _apiService.createBus(result);
        setState(() {
          _buses.insert(0, Bus.fromJson(newBus));
        });
        
        // Show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bus ${result['busCode']} added successfully'),
            backgroundColor: DashboardTheme.success,
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DashboardTheme.error,
          ),
        );
        print('Bus creation error: $e');
      }
    }
  }

  Future<void> _deleteBus(int busId) async {
    try {
      await _apiService.deleteBus(busId.toString());
      setState(() {
        _buses.removeWhere((bus) => bus.id == busId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus supprimé avec succès'),
          backgroundColor: DashboardTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: DashboardTheme.error,
        ),
      );
    }
  }

  Future<void> _editBus(int busId) async {
    Bus? bus;
    for (final b in _buses) {
      if (b.id == busId) {
        bus = b;
        break;
      }
    }
    if (bus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus introuvable'),
          backgroundColor: DashboardTheme.error,
        ),
      );
      return;
    }

    final codeCtrl = TextEditingController(text: bus.busNumber);
    final routeCtrl = TextEditingController(text: bus.route);
    final capacityCtrl = TextEditingController(text: bus.totalSeats.toString());
    final priceCtrl = TextEditingController(text: bus.price.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        final isMobile = ResponsiveLayout.isMobile(context);
        return AlertDialog(
          title: const Text('Modifier le bus'),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: 24,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(labelText: 'Code bus'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: routeCtrl,
                      decoration: const InputDecoration(labelText: 'Trajet'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: capacityCtrl,
                      decoration: const InputDecoration(labelText: 'Places totales'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Nombre invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Prix (FCFA)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Prix invalide';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, {
                  'bus_number': codeCtrl.text.trim(),
                  'route': routeCtrl.text.trim(),
                  'total_seats': int.parse(capacityCtrl.text.trim()),
                  'price': double.parse(priceCtrl.text.trim()),
                });
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    try {
      final updated = await _apiService.updateBus(busId.toString(), result);
      final busPayload = (updated['bus'] is Map<String, dynamic>)
          ? updated['bus'] as Map<String, dynamic>
          : updated;
      final updatedBus = Bus.fromJson({
        ...busPayload,
        'price': busPayload['price'] ?? result['price'],
      });
      setState(() {
        final index = _buses.indexWhere((b) => b.id == busId);
        if (index != -1) {
          _buses[index] = updatedBus;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus modifié avec succès'),
          backgroundColor: DashboardTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur modification: $e'),
          backgroundColor: DashboardTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveLayout.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(),
          const SizedBox(height: 32),

          // Stats Overview
          _buildStatsOverview(),
          const SizedBox(height: 32),

          // Buses List
          _buildBusesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flotte de bus',
          style: DashboardTheme.headlineSmall.copyWith(
            color: DashboardTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ajoutez, modifiez et suivez tous vos bus.',
          style: DashboardTheme.bodyMedium.copyWith(
            color: DashboardTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        FilledButton.icon(
          onPressed: _showAddBusDialog,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: DashboardTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
            ),
          ),
          icon: Icon(
            Icons.add_rounded,
            size: 20,
            color: Colors.white,
          ),
          label: Text(
            'Ajouter un bus',
            style: DashboardTheme.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _importBuses,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: BorderSide(
              color: DashboardTheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
            ),
          ),
          icon: Icon(
            Icons.import_export_rounded,
            size: 20,
            color: DashboardTheme.primary,
          ),
          label: Text(
            'Importer',
            style: DashboardTheme.labelMedium.copyWith(
              color: DashboardTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _showImportTemplate,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: BorderSide(
              color: DashboardTheme.info.withOpacity(0.3),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
            ),
          ),
          icon: Icon(
            Icons.description_outlined,
            size: 20,
            color: DashboardTheme.info,
          ),
          label: Text(
            'Template',
            style: DashboardTheme.labelMedium.copyWith(
              color: DashboardTheme.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final totalBuses = _buses.length;
    // Derive status from available seats
    final availableBuses = _buses.where((bus) => bus.availableSeats > 0).length;
    final inTransit = _buses.where((bus) => bus.availableSeats == 0 && bus.totalSeats > 0).length;
    final inMaintenance = 0; // Placeholder since API doesn't provide maintenance status

    return ResponsiveGrid(
      children: [
        _StatCard(
          title: 'Total bus',
          value: '$totalBuses',
          icon: Icons.directions_bus_filled_rounded,
          color: DashboardTheme.primary,
        ),
        _StatCard(
          title: 'Disponibles',
          value: '$availableBuses',
          icon: Icons.check_circle_rounded,
          color: DashboardTheme.success,
        ),
        _StatCard(
          title: 'En transit',
          value: '$inTransit',
          icon: Icons.navigation_rounded,
          color: DashboardTheme.info,
        ),
        _StatCard(
          title: 'Maintenance',
          value: '$inMaintenance',
          icon: Icons.build_rounded,
          color: DashboardTheme.warning,
        ),
      ],
      spacing: 20,
    );
  }

  Widget _buildBusesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: DashboardTheme.error),
            const SizedBox(height: 16),
            Text('Erreur: $_errorMessage', style: DashboardTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBuses,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    final isMobile = ResponsiveLayout.isMobile(context);
    return Container(
      decoration: DashboardTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Liste des bus',
                    style: DashboardTheme.titleMedium.copyWith(
                      color: DashboardTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_buses.length} bus dans la flotte',
                    style: DashboardTheme.bodySmall.copyWith(
                      color: DashboardTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _loadBuses,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualiser',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: DashboardTheme.onSurfaceVariant,
                              size: 20,
                            ),
                            hintText: 'Rechercher un bus…',
                            filled: true,
                            fillColor: DashboardTheme.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Liste des bus',
                          style: DashboardTheme.titleMedium.copyWith(
                            color: DashboardTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_buses.length} bus dans la flotte',
                          style: DashboardTheme.bodySmall.copyWith(
                            color: DashboardTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _loadBuses,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualiser',
                      ),
                      SizedBox(
                        width: 240,
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: DashboardTheme.onSurfaceVariant,
                              size: 20,
                            ),
                            hintText: 'Rechercher un bus…',
                            filled: true,
                            fillColor: DashboardTheme.surfaceVariant,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 980),
                child: DataTable(
                headingRowColor: WidgetStateProperty.all(DashboardTheme.surfaceVariant),
                headingTextStyle: DashboardTheme.labelMedium.copyWith(
                  color: DashboardTheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                dataTextStyle: DashboardTheme.bodyMedium.copyWith(
                  color: DashboardTheme.onSurface,
                ),
                columns: const [
                  DataColumn(label: Text('Numéro')),
                  DataColumn(label: Text('Trajet')),
                  DataColumn(label: Text('Départ')),
                  DataColumn(label: Text('Places')),
                  DataColumn(label: Text('Prix')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _buses
                    .map(
                      (bus) => DataRow(
                        cells: [
                          DataCell(Text(bus.busNumber)),
                          DataCell(Text(bus.route)),
                          DataCell(Text('${bus.departureTime.hour}:${bus.departureTime.minute.toString().padLeft(2, '0')}')),
                          DataCell(Text('${bus.availableSeats}/${bus.totalSeats}')),
                          DataCell(Text('${bus.price.toInt()} FCFA')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Modifier',
                                  onPressed: () => _editBus(bus.id),
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: DashboardTheme.primary,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Supprimer',
                                  onPressed: () => _deleteBus(bus.id),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: DashboardTheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _importBuses() async {
    try {
      // Show file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Importing ${file.name}...'),
            backgroundColor: DashboardTheme.info,
          ),
        );

        List<Bus> importedBuses = [];
        List<String> errors = [];

        try {
          // Parse CSV
          String csvContent = String.fromCharCodes(file.bytes!);
          List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvContent);
          
          // Skip header row and process data
          for (int i = 1; i < csvTable.length; i++) {
            try {
              List<dynamic> row = csvTable[i];
              if (row.length >= 4) {
                final busData = {
                  'bus_number': row[0].toString().trim(),
                  'route': row[1].toString().trim(),
                  'total_seats': int.tryParse(row[2].toString()) ?? 50,
                  'price': double.tryParse(row[3].toString()) ?? 2500.0,
                  'departure_time': row.length > 4 ? row[4].toString().trim() : '08:00',
                  'arrival_time': row.length > 5 ? row[5].toString().trim() : '12:00',
                };
                
                // Validate required fields
                if ((busData['bus_number'] as String).isNotEmpty && (busData['route'] as String).isNotEmpty) {
                  final newBus = await _apiService.createBus(busData);
                  importedBuses.add(Bus.fromJson(newBus));
                } else {
                  errors.add('Row ${i + 1}: Missing required fields (bus number or route)');
                }
              }
            } catch (e) {
              errors.add('Row ${i + 1}: ${e.toString()}');
            }
          }

          // Show results
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (importedBuses.isNotEmpty) {
            setState(() {
              _buses.insertAll(0, importedBuses);
            });
            
            String successMessage = 'Successfully imported ${importedBuses.length} buses';
            if (errors.isNotEmpty) {
              successMessage += ' with ${errors.length} errors';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: DashboardTheme.success,
              ),
            );
          } else if (errors.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Import failed: ${errors.first}'),
                backgroundColor: DashboardTheme.error,
              ),
            );
          }

          // Show detailed errors if any
          if (errors.length > 1) {
            _showImportErrors(errors);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import error: ${e.toString()}'),
              backgroundColor: DashboardTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File selection error: ${e.toString()}'),
          backgroundColor: DashboardTheme.error,
        ),
      );
    }
  }

  void _showImportErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Errors'),
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.isMobile(context) ? 16 : 40,
          vertical: 24,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 380),
          child: ListView.builder(
            itemCount: errors.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(errors[index], style: DashboardTheme.bodySmall),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImportTemplate() {
    final templateContent = '''
bus_number,route,total_seats,price,departure_time,arrival_time
BUS-001,"Ouagadougou - Bobo-Dioulasso",50,2500,08:00,12:00
BUS-002,"Ouagadougou - Koudougou",45,2000,09:00,10:30
BUS-003,"Bobo-Dioulasso - Ouagadougou",50,2500,14:00,18:00
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Template'),
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.isMobile(context) ? 16 : 40,
          vertical: 24,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 460),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Download this CSV template:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DashboardTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  templateContent,
                  style: DashboardTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Required columns:'),
              const Text('• bus_number (unique identifier)'),
              const Text('• route (destination route)'),
              const Text('• total_seats (number of seats)'),
              const Text('• price (ticket price in FCFA)'),
              const Text('• departure_time (HH:MM format)'),
              const Text('• arrival_time (HH:MM format)'),
            ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DashboardTheme.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            DashboardTheme.surface.withOpacity(0.95),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: DashboardTheme.titleLarge.copyWith(
                color: DashboardTheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: DashboardTheme.bodySmall.copyWith(
                color: DashboardTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
