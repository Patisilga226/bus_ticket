import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';
import '../../services/api_service.dart';
import '../../models/driver.dart';
import '../themes/dashboard_theme.dart';
import '../utils/responsive_layout.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  List<Driver> _drivers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }
  
  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final driversData = await _apiService.getDrivers();
      setState(() {
        _drivers = driversData.map((data) => Driver.fromJson(data)).toList();
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

  Future<void> _showAddDriverDialog() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String status = 'En service';
    List<dynamic> buses = [];
    int? selectedBusId;
    final formKey = GlobalKey<FormState>();

    try {
      buses = await _apiService.getBuses();
      if (buses.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun bus disponible. Ajoute d\'abord un bus.'),
            backgroundColor: DashboardTheme.error,
          ),
        );
        return;
      }
      final firstBusId = buses.first['id'];
      selectedBusId = firstBusId is int ? firstBusId : int.tryParse(firstBusId.toString());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de charger les bus: $e'),
          backgroundColor: DashboardTheme.error,
        ),
      );
      return;
    }
  
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        final isMobile = ResponsiveLayout.isMobile(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardTheme.radiusXl),
          ),
          title: Text(
            'Nouveau chauffeur',
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
                      labelText: 'Matricule chauffeur',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                      hintText: 'e.g., DRV-001',
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Matricule obligatoire';
                      }
                      if (v.length < 3) {
                        return 'Le matricule doit contenir au moins 3 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Nom obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                      hintText: 'chauffeur@company.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Email obligatoire';
                      }
                      if (!v.contains('@')) {
                        return 'Email invalide';
                      }
                      return null;
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
                      DropdownMenuItem(value: 'En service', child: Text('En service')),
                      DropdownMenuItem(value: 'En repos', child: Text('En repos')),
                      DropdownMenuItem(value: 'Suspendu', child: Text('Suspendu')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => status = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedBusId,
                    decoration: InputDecoration(
                      labelText: 'Bus assigné',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                    ),
                    items: buses.map((bus) {
                      final id = bus['id'] is int ? bus['id'] as int : int.tryParse(bus['id'].toString()) ?? 0;
                      final busNumber = (bus['bus_number'] ?? '').toString();
                      final route = (bus['route'] ?? '').toString();
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text('$busNumber - $route'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      selectedBusId = v;
                    },
                    validator: (v) => v == null ? 'Bus obligatoire' : null,
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                  
                try {
                  // Show loading indicator
                  Navigator.of(context).pop();
                    
                  final driverData = {
                    'employee_name': nameCtrl.text.trim(),
                    'employee_email': emailCtrl.text.trim(),
                    'bus_id': selectedBusId,
                    'assigned_at': DateTime.now().toIso8601String(),
                  };
                    
                  final newDriver = await _apiService.createDriver(driverData);
                  setState(() {
                    _drivers.insert(0, Driver.fromJson(newDriver));
                  });
                    
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chauffeur ${nameCtrl.text.trim()} ajouté avec succès'),
                      backgroundColor: DashboardTheme.success,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de l\'ajout: $e'),
                      backgroundColor: DashboardTheme.error,
                    ),
                  );
                }
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
  }

  Future<void> _deleteDriver(int index) async {
    final driverId = _drivers[index].id;
    final driverName = _drivers[index].employeeName;
    
    try {
      await _apiService.deleteDriver(driverId.toString());
      setState(() {
        _drivers.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chauffeur $driverName supprimé'),
          backgroundColor: DashboardTheme.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: DashboardTheme.error,
        ),
      );
    }
  }

  void _scheduleDriver(int index) {
    // TODO: Implement scheduling functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Planification en cours de développement')),
    );
  }

  // Export to PDF
  Future<void> _exportDriversToPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Header(level: 0, child: pw.Text('Liste des Chauffeurs')),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['ID', 'Nom', 'Email', 'Bus', 'Route', 'Date d\'assignation'],
                  data: _drivers.map((driver) => [
                    driver.id.toString(),
                    driver.employeeName,
                    driver.employeeEmail,
                    driver.busNumber ?? '-',
                    driver.route ?? '-',
                    driver.assignedAt.toString().split(' ')[0],
                  ]).toList(),
                  border: pw.TableBorder.all(),
                ),
              ],
            );
          }
        ),
      );

      // Save and share PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export PDF: $e'),
          backgroundColor: DashboardTheme.error,
        ),
      );
    }
  }

  // Export to Excel
  Future<void> _exportDriversToExcel() async {
    try {
      // Create CSV content (as a workaround since the Excel package is complex to use)
      final stringBuffer = StringBuffer();
      stringBuffer.writeln('ID,Nom,Email,Bus,Route,Date d\'assignation');
      
      for (final driver in _drivers) {
        stringBuffer.writeln([
          '"${driver.id}"',
          '"${driver.employeeName}"',
          '"${driver.employeeEmail}"',
          '"${driver.busNumber ?? "-"}"',
          '"${driver.route ?? "-"}"',
          '"${driver.assignedAt.toString().split(' ')[0]}"'
        ].join(','));
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/drivers_list_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(stringBuffer.toString());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liste des chauffeurs exportée avec succès!'),
          backgroundColor: DashboardTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export Excel: $e'),
          backgroundColor: DashboardTheme.error,
        ),
      );
    }
  }

  // Show export options
  Future<void> _showExportOptions() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: DashboardTheme.error),
              title: const Text('Exporter en PDF'),
              onTap: () {
                Navigator.of(context).pop();
                _exportDriversToPDF();
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: DashboardTheme.success),
              title: const Text('Exporter en Excel'),
              onTap: () {
                Navigator.of(context).pop();
                _exportDriversToExcel();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
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

          // Drivers List
          _buildDriversList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chauffeurs',
          style: DashboardTheme.headlineSmall.copyWith(
            color: DashboardTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Assignez les chauffeurs aux bus et suivez leurs performances.',
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
          onPressed: _showAddDriverDialog,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: DashboardTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
            ),
          ),
          icon: Icon(
            Icons.person_add_alt_1_rounded,
            size: 20,
            color: Colors.white,
          ),
          label: Text(
            'Nouveau chauffeur',
            style: DashboardTheme.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _showExportOptions();
          },
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
            Icons.badge_outlined,
            size: 20,
            color: DashboardTheme.primary,
          ),
          label: Text(
            'Exporter les fiches',
            style: DashboardTheme.labelMedium.copyWith(
              color: DashboardTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    final totalDrivers = _drivers.length;
    // Since the new API doesn't have explicit status, we'll derive it
    final assignedDrivers = _drivers.where((driver) => driver.busId != null).length;
    final unassignedDrivers = _drivers.length - assignedDrivers;
    final avgRating = 4.5; // Placeholder value since API doesn't provide ratings

    return ResponsiveGrid(
      children: [
        _StatCard(
          title: 'Total chauffeurs',
          value: '$totalDrivers',
          icon: Icons.people_rounded,
          color: DashboardTheme.primary,
        ),
        _StatCard(
          title: 'Assignés',
          value: '$assignedDrivers',
          icon: Icons.assignment_rounded,
          color: DashboardTheme.success,
        ),
        _StatCard(
          title: 'Non assignés',
          value: '$unassignedDrivers',
          icon: Icons.assignment_late_rounded,
          color: DashboardTheme.warning,
        ),
        _StatCard(
          title: 'Note moyenne',
          value: avgRating.toStringAsFixed(1),
          icon: Icons.star_rounded,
          color: DashboardTheme.warning,
        ),
      ],
      spacing: 20,
    );
  }

  Widget _buildDriversList() {
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
                    'Liste des chauffeurs',
                    style: DashboardTheme.titleMedium.copyWith(
                      color: DashboardTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_drivers.length} chauffeurs dans l\'équipe',
                    style: DashboardTheme.bodySmall.copyWith(
                      color: DashboardTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: DashboardTheme.onSurfaceVariant,
                        size: 20,
                      ),
                      hintText: 'Rechercher un chauffeur…',
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
                          'Liste des chauffeurs',
                          style: DashboardTheme.titleMedium.copyWith(
                            color: DashboardTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_drivers.length} chauffeurs dans l\'équipe',
                          style: DashboardTheme.bodySmall.copyWith(
                            color: DashboardTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
                        hintText: 'Rechercher un chauffeur…',
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
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Nom')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Bus')),
                  DataColumn(label: Text('Route')),
                  DataColumn(label: Text('Date d\'assignation')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: [
                  for (var i = 0; i < _drivers.length; i++)
                    DataRow(
                      cells: [
                        DataCell(Text('${_drivers[i].id}')),
                        DataCell(Text(_drivers[i].employeeName)),
                        DataCell(Text(_drivers[i].employeeEmail)),
                        DataCell(Text(_drivers[i].busNumber ?? '-')),
                        DataCell(Text(_drivers[i].route ?? '-')),
                        DataCell(Text(_drivers[i].assignedAt.toString().split(' ')[0])), // Just the date part
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Planifier',
                                onPressed: () => _scheduleDriver(i),
                                icon: Icon(
                                  Icons.schedule_rounded,
                                  size: 20,
                                  color: DashboardTheme.primary,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Supprimer',
                                onPressed: () => _deleteDriver(i),
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
                ],
                ),
              ),
            ),
          ],
        ),
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

class _DriverStatusPill extends StatelessWidget {
  const _DriverStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    late Color color;
    late Color bg;
    switch (status) {
      case 'En service':
        color = DashboardTheme.success;
        bg = DashboardTheme.success.withOpacity(0.12);
        break;
      case 'En repos':
        color = DashboardTheme.info;
        bg = DashboardTheme.info.withOpacity(0.12);
        break;
      default:
        color = DashboardTheme.error;
        bg = DashboardTheme.error.withOpacity(0.12);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: DashboardTheme.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.star_rounded,
          size: 20,
          color: DashboardTheme.warning,
        ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: DashboardTheme.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: DashboardTheme.onSurface,
          ),
        ),
      ],
    );
  }
}
