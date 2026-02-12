import 'package:flutter/material.dart';
import '../themes/dashboard_theme.dart';
import '../utils/responsive_layout.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';

// Define Passenger model locally since there seems to be an import issue
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
}

class PassengersPage extends StatefulWidget {
  const PassengersPage({super.key});

  @override
  State<PassengersPage> createState() => _PassengersPageState();
}

class _PassengersPageState extends State<PassengersPage> {
  final List<Passenger> _passengers = [
    Passenger(
      id: '1',
      name: 'Amadou Traoré',
      city: 'Ouaga',
      totalTrips: 12,
      status: 'Actif',
      lastTravelDate: '2024-01-15',
      createdAt: DateTime(2023, 5, 10),
    ),
    Passenger(
      id: '2',
      name: 'Fatima Sawadogo',
      city: 'Bobo',
      totalTrips: 8,
      status: 'Actif',
      lastTravelDate: '2024-01-10',
      createdAt: DateTime(2023, 7, 12),
    ),
    Passenger(
      id: '3',
      name: 'Mariam Compaoré',
      city: 'Koudougou',
      totalTrips: 3,
      status: 'Inactif',
      lastTravelDate: '2023-11-20',
      createdAt: DateTime(2023, 3, 5),
    ),
    Passenger(
      id: '4',
      name: 'Ibrahim Ouédraogo',
      city: 'Ouaga',
      totalTrips: 5,
      status: 'Actif',
      lastTravelDate: '2024-01-12',
      createdAt: DateTime(2023, 9, 18),
    ),
    Passenger(
      id: '5',
      name: 'Adama Konaté',
      city: 'Bobo',
      totalTrips: 15,
      status: 'Actif',
      lastTravelDate: '2024-01-18',
      createdAt: DateTime(2023, 2, 1),
    ),
    Passenger(
      id: '6',
      name: 'Aminata Diarra',
      city: 'Ouaga',
      totalTrips: 7,
      status: 'Inactif',
      lastTravelDate: '2023-12-05',
      createdAt: DateTime(2023, 6, 22),
    ),
  ];

  void _viewPassengerDetails(Passenger passenger) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du passager'),
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.isMobile(context) ? 16 : 40,
          vertical: 24,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('ID:', passenger.id),
                _buildDetailRow('Nom:', passenger.name),
                _buildDetailRow('Ville:', passenger.city),
                _buildDetailRow('Nombre de voyages:', passenger.totalTrips.toString()),
                _buildDetailRow('Statut:', passenger.status),
                _buildDetailRow('Dernier voyage:', passenger.lastTravelDate ?? 'Non spécifié'),
                _buildDetailRow('Date d\'inscription:', passenger.createdAt.toString().split(' ')[0]),
                if (passenger.updatedAt != null)
                  _buildDetailRow('Dernière mise à jour:', passenger.updatedAt!.toString().split(' ')[0]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _exportPassengerData() {
    _showExportOptions();
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
                _exportPassengersToPDF();
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: DashboardTheme.success),
              title: const Text('Exporter en Excel'),
              onTap: () {
                Navigator.of(context).pop();
                _exportPassengersToExcel();
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

  // Export to PDF
  Future<void> _exportPassengersToPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Header(level: 0, child: pw.Text('Liste des Passagers')),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['ID', 'Nom', 'Ville', 'Voyages', 'Statut', 'Dernier voyage'],
                  data: _passengers.map((passenger) => [
                    passenger.id,
                    passenger.name,
                    passenger.city,
                    passenger.totalTrips.toString(),
                    passenger.status,
                    passenger.lastTravelDate ?? '-',
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
  Future<void> _exportPassengersToExcel() async {
    try {
      // Create CSV content (as a workaround since the Excel package is complex to use)
      final stringBuffer = StringBuffer();
      stringBuffer.writeln('ID,Nom,Ville,Voyages,Statut,Dernier voyage,Date inscription,Mise à jour');

      for (final passenger in _passengers) {
        stringBuffer.writeln([
          '"${passenger.id}"',
          '"${passenger.name}"',
          '"${passenger.city}"',
          '"${passenger.totalTrips}"',
          '"${passenger.status}"',
          '"${passenger.lastTravelDate ?? "-"}"',
          '"${passenger.createdAt.toString().split(' ')[0]}"',
          '"${passenger.updatedAt?.toString().split(' ')[0] ?? "-"}"'
        ].join(','));
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/passengers_list_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(stringBuffer.toString());

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liste des passagers exportée avec succès!'),
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

          // Stats Overview
          _buildStatsOverview(),
          const SizedBox(height: 32),

          // Action Button
          _buildActionButton(),
          const SizedBox(height: 32),

          // Passengers List
          _buildPassengersList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passagers',
          style: DashboardTheme.headlineSmall.copyWith(
            color: DashboardTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Visualisez vos meilleurs clients et leur historique de voyages.',
          style: DashboardTheme.bodyMedium.copyWith(
            color: DashboardTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    final totalPassengers = _passengers.length;
    final activePassengers = _passengers.where((p) => p.status == 'Actif').length;
    final inactivePassengers = _passengers.where((p) => p.status == 'Inactif').length;
    final totalTrips = _passengers.fold(0, (sum, passenger) => sum + passenger.totalTrips);

    return ResponsiveGrid(
      children: [
        _PassengerStatCard(
          title: 'Total passagers',
          value: '$totalPassengers',
          subtitle: 'dans le système',
          icon: Icons.people_rounded,
          color: DashboardTheme.primary,
        ),
        _PassengerStatCard(
          title: 'Actifs',
          value: '$activePassengers',
          subtitle: 'clients réguliers',
          icon: Icons.check_circle_rounded,
          color: DashboardTheme.success,
        ),
        _PassengerStatCard(
          title: 'Inactifs',
          value: '$inactivePassengers',
          subtitle: 'à recontacter',
          icon: Icons.block_rounded,
          color: DashboardTheme.warning,
        ),
        _PassengerStatCard(
          title: 'Voyages totaux',
          value: '$totalTrips',
          subtitle: 'réservations',
          icon: Icons.flight_takeoff_rounded,
          color: DashboardTheme.info,
        ),
      ],
      spacing: 20,
    );
  }

  Widget _buildActionButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: _exportPassengerData,
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
          Icons.download_rounded,
          size: 20,
          color: DashboardTheme.primary,
        ),
        label: Text(
          'Exporter les données',
          style: DashboardTheme.labelMedium.copyWith(
            color: DashboardTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPassengersList() {
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
                    'Vue clients',
                    style: DashboardTheme.titleMedium.copyWith(
                      color: DashboardTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_passengers.length} passagers dans la base',
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
                      hintText: 'Rechercher un passager…',
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
                          'Vue clients',
                          style: DashboardTheme.titleMedium.copyWith(
                            color: DashboardTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_passengers.length} passagers dans la base',
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
                        hintText: 'Rechercher un passager…',
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
                constraints: const BoxConstraints(minWidth: 920),
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
                  DataColumn(label: Text('Nom complet')),
                  DataColumn(label: Text('Ville')),
                  DataColumn(label: Text('Voyages')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Fréquence')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _passengers
                    .map(
                      (passenger) => DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: DashboardTheme.primary.withOpacity(0.1),
                                  child: Text(
                                    passenger.name.split(' ').map((n) => n[0]).take(2).join(),
                                    style: DashboardTheme.labelMedium.copyWith(
                                      color: DashboardTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(passenger.name),
                              ],
                            ),
                          ),
                          DataCell(Text(passenger.city)),
                          DataCell(
                            Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number_rounded,
                                  size: 16,
                                  color: DashboardTheme.info,
                                ),
                                const SizedBox(width: 6),
                                Text('${passenger.totalTrips}'),
                              ],
                            ),
                          ),
                          DataCell(_PassengerStatusPill(status: passenger.status)),
                          DataCell(_FrequencyIndicator(trips: passenger.totalTrips)),
                          DataCell(
                            IconButton(
                              tooltip: 'Voir détails',
                              onPressed: () => _viewPassengerDetails(passenger),
                              icon: Icon(
                                Icons.visibility_outlined,
                                size: 20,
                                color: DashboardTheme.primary,
                              ),
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
}

class _PassengerStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _PassengerStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
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
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: DashboardTheme.labelSmall.copyWith(
                color: DashboardTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassengerStatusPill extends StatelessWidget {
  const _PassengerStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Actif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? DashboardTheme.success.withOpacity(0.12)
            : DashboardTheme.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
        border: Border.all(
          color: isActive 
              ? DashboardTheme.success.withOpacity(0.2)
              : DashboardTheme.warning.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.block_rounded,
            size: 16,
            color: isActive ? DashboardTheme.success : DashboardTheme.warning,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: DashboardTheme.labelMedium.copyWith(
              color: isActive ? DashboardTheme.success : DashboardTheme.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyIndicator extends StatelessWidget {
  const _FrequencyIndicator({required this.trips});

  final int trips;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    if (trips >= 10) {
      color = DashboardTheme.success;
      label = 'Régulier';
    } else if (trips >= 5) {
      color = DashboardTheme.info;
      label = 'Occasionnel';
    } else {
      color = DashboardTheme.warning;
      label = 'Nouveau';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: DashboardTheme.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
