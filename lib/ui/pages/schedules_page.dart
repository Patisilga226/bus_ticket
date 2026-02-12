import 'package:flutter/material.dart';
import 'dart:math';
import '../themes/dashboard_theme.dart';
import '../utils/responsive_layout.dart';
import '../../services/api_service.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  final List<_ScheduleRow> _schedules = [
    _ScheduleRow('Ouaga → Bobo', 'BUS-001', '06:30', '10:45', 'Quotidien'),
    _ScheduleRow('Bobo → Ouaga', 'BUS-014', '14:00', '18:15', 'Quotidien'),
    _ScheduleRow('Ouaga → Koudougou', 'BUS-021', '08:00', '09:30', 'Lun–Sam'),
    _ScheduleRow('Koudougou → Ouaga', 'BUS-032', '17:30', '19:00', 'Lun–Ven'),
  ];
  
  final ApiService _apiService = ApiService();

  void _addNewSchedule() {
    _showNewScheduleDialog();
  }

  Future<void> _showNewScheduleDialog() async {
    final routeCtrl = TextEditingController();
    final busCtrl = TextEditingController();
    final departureTimeCtrl = TextEditingController(text: '08:00');
    final arrivalTimeCtrl = TextEditingController(text: '12:00');
    String frequency = 'Quotidien';
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
            'Nouvel horaire',
            style: DashboardTheme.titleLarge.copyWith(
              color: DashboardTheme.onSurface,
            ),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: 24,
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  TextFormField(
                    controller: routeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Trajet',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                      hintText: 'e.g., Ouaga → Bobo-Dioulasso',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Trajet obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: busCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bus',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                      hintText: 'e.g., BUS-001',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Bus obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(
                      children: [
                        TextFormField(
                          controller: departureTimeCtrl,
                          decoration: InputDecoration(
                            labelText: 'Départ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                            ),
                            hintText: 'HH:MM',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Heure de départ requise';
                            }
                            if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(v)) {
                              return 'Format HH:MM requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: arrivalTimeCtrl,
                          decoration: InputDecoration(
                            labelText: 'Arrivée',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                            ),
                            hintText: 'HH:MM',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Heure d\'arrivée requise';
                            }
                            if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(v)) {
                              return 'Format HH:MM requis';
                            }
                            return null;
                          },
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: departureTimeCtrl,
                            decoration: InputDecoration(
                              labelText: 'Départ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                              ),
                              hintText: 'HH:MM',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Heure de départ requise';
                              }
                              if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(v)) {
                                return 'Format HH:MM requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: arrivalTimeCtrl,
                            decoration: InputDecoration(
                              labelText: 'Arrivée',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                              ),
                              hintText: 'HH:MM',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Heure d\'arrivée requise';
                              }
                              if (!RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(v)) {
                                return 'Format HH:MM requis';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: InputDecoration(
                      labelText: 'Fréquence',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Quotidien', child: Text('Quotidien')),
                      DropdownMenuItem(value: 'Lun–Ven', child: Text('Lundi à Vendredi')),
                      DropdownMenuItem(value: 'Lun–Sam', child: Text('Lundi à Samedi')),
                      DropdownMenuItem(value: 'Weekend', child: Text('Weekend')),
                      DropdownMenuItem(value: 'Personnalisé', child: Text('Personnalisé')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => frequency = v);
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
                  'route': routeCtrl.text.trim(),
                  'bus': busCtrl.text.trim(),
                  'departureTime': departureTimeCtrl.text.trim(),
                  'arrivalTime': arrivalTimeCtrl.text.trim(),
                  'frequency': frequency,
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: DashboardTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
                ),
              ),
              child: Text(
                'Créer',
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
            content: Text('Creating schedule...'),
            backgroundColor: DashboardTheme.info,
          ),
        );

        // In a real implementation, this would call the API
        // For now, we'll add it to the local list
        setState(() {
          _schedules.add(_ScheduleRow(
            result['route'] as String,
            result['bus'] as String,
            result['departureTime'] as String,
            result['arrivalTime'] as String,
            result['frequency'] as String,
          ));
        });

        // Show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule ${result['route']} added successfully'),
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
      }
    }
  }

  void _viewOnMap() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bus Routes Map'),
        insetPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.isMobile(context) ? 16 : 40,
          vertical: 24,
        ),
        content: SizedBox(
          width: ResponsiveLayout.isMobile(context) ? 320 : 600,
          height: ResponsiveLayout.isMobile(context) ? 360 : 500,
          child: _BusMapWidget(schedules: _schedules),
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

  void _editSchedule(String route) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modification de l\'horaire $route')),
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

          // Schedules List
          _buildSchedulesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horaires & trajets',
          style: DashboardTheme.headlineSmall.copyWith(
            color: DashboardTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Planifiez les départs, durées et fréquences de vos trajets.',
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
          onPressed: _addNewSchedule,
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
            'Nouvel horaire',
            style: DashboardTheme.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _viewOnMap,
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
            Icons.map_rounded,
            size: 20,
            color: DashboardTheme.primary,
          ),
          label: Text(
            'Voir sur la carte',
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
    final totalSchedules = _schedules.length;
    const dailySchedules = 2;
    const weeklySchedules = 2;

    return ResponsiveGrid(
      children: [
        _ScheduleStatCard(
          title: 'Total horaires',
          value: '$totalSchedules',
          subtitle: 'trajets programmés',
          icon: Icons.schedule_rounded,
          color: DashboardTheme.primary,
        ),
        _ScheduleStatCard(
          title: 'Départs quotidiens',
          value: '$dailySchedules',
          subtitle: 'par jour',
          icon: Icons.today_rounded,
          color: DashboardTheme.success,
        ),
        _ScheduleStatCard(
          title: 'Départs hebdomadaires',
          value: '$weeklySchedules',
          subtitle: 'jours/semaine',
          icon: Icons.calendar_view_week_rounded,
          color: DashboardTheme.info,
        ),
        _ScheduleStatCard(
          title: 'Fréquence moyenne',
          value: '5.5',
          subtitle: 'jours/semaine',
          icon: Icons.autorenew_rounded,
          color: DashboardTheme.warning,
        ),
      ],
      spacing: 20,
    );
  }

  Widget _buildSchedulesList() {
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
                    'Planning des départs',
                    style: DashboardTheme.titleMedium.copyWith(
                      color: DashboardTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_schedules.length} trajets programmés',
                    style: DashboardTheme.bodySmall.copyWith(
                      color: DashboardTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DateFilterDropdown(),
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
                          'Planning des départs',
                          style: DashboardTheme.titleMedium.copyWith(
                            color: DashboardTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_schedules.length} trajets programmés',
                          style: DashboardTheme.bodySmall.copyWith(
                            color: DashboardTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DateFilterDropdown(),
                ],
              ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1080),
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
                  DataColumn(label: Text('Trajet')),
                  DataColumn(label: Text('Bus')),
                  DataColumn(label: Text('Heure départ')),
                  DataColumn(label: Text('Heure arrivée')),
                  DataColumn(label: Text('Durée')),
                  DataColumn(label: Text('Fréquence')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _schedules
                    .map(
                      (schedule) => DataRow(
                        cells: [
                          DataCell(Text(schedule.route)),
                          DataCell(Text(schedule.bus)),
                          DataCell(
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: DashboardTheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(schedule.start),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  size: 16,
                                  color: DashboardTheme.success,
                                ),
                                const SizedBox(width: 6),
                                Text(schedule.end),
                              ],
                            ),
                          ),
                          DataCell(Text(_calculateDuration(schedule.start, schedule.end))),
                          DataCell(_FrequencyChip(label: schedule.frequency)),
                          DataCell(
                            IconButton(
                              tooltip: 'Modifier',
                              onPressed: () => _editSchedule(schedule.route),
                              icon: Icon(
                                Icons.edit_outlined,
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

  String _calculateDuration(String start, String end) {
    try {
      // Parse the time strings (assuming HH:MM format)
      final startTimeParts = start.split(':');
      final endTimeParts = end.split(':');
      
      if (startTimeParts.length == 2 && endTimeParts.length == 2) {
        final startHour = int.tryParse(startTimeParts[0]) ?? 0;
        final startMinute = int.tryParse(startTimeParts[1]) ?? 0;
        final endHour = int.tryParse(endTimeParts[0]) ?? 0;
        final endMinute = int.tryParse(endTimeParts[1]) ?? 0;
        
        // Calculate total minutes
        int startTotalMinutes = startHour * 60 + startMinute;
        int endTotalMinutes = endHour * 60 + endMinute;
        
        // Handle overnight trips (when end time is less than start time)
        if (endTotalMinutes < startTotalMinutes) {
          endTotalMinutes += 24 * 60; // Add 24 hours in minutes
        }
        
        int durationMinutes = endTotalMinutes - startTotalMinutes;
        int hours = durationMinutes ~/ 60;
        int minutes = durationMinutes % 60;
        
        if (hours > 0) {
          return '${hours}h${minutes.toString().padLeft(2, '0')}';
        } else {
          return '${minutes}min';
        }
      }
    } catch (e) {
      // If parsing fails, return a default value
      return '4h15';
    }
    return '4h15'; // Fallback
  }
}

class _ScheduleRow {
  final String route;
  final String bus;
  final String start;
  final String end;
  final String frequency;

  _ScheduleRow(this.route, this.bus, this.start, this.end, this.frequency);
}

class _ScheduleStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ScheduleStatCard({
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

class _DateFilterDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: DashboardTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.today_outlined,
            size: 18,
            color: DashboardTheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Aujourd\'hui',
            style: DashboardTheme.labelMedium.copyWith(
              color: DashboardTheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: DashboardTheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardTheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
        border: Border.all(
          color: DashboardTheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: DashboardTheme.labelMedium.copyWith(
          color: DashboardTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BusMapWidget extends StatelessWidget {
  final List<_ScheduleRow> schedules;

  const _BusMapWidget({required this.schedules});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Stack(
        children: [
          // Background grid representing the map
          CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: _MapGridPainter(),
          ),
          
          // Route lines and markers
          ..._buildRouteLines(),
          
          // City markers
          ..._buildCityMarkers(),
          
          // Legend
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Legend:', style: DashboardTheme.labelMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [Container(width: 20, height: 3, color: DashboardTheme.primary), const SizedBox(width: 8), const Text('Bus Routes')]),
                  const SizedBox(height: 4),
                  Row(children: [Icon(Icons.location_on, color: DashboardTheme.error, size: 20), const SizedBox(width: 8), const Text('Major Cities')]),
                  const SizedBox(height: 4),
                  Row(children: [Icon(Icons.location_on, color: DashboardTheme.warning, size: 16), const SizedBox(width: 8), const Text('Bus Stops')]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRouteLines() {
    final List<Widget> lines = [];
    
    // Define route coordinates (simplified for visualization)
    final routeCoordinates = {
      'Ouaga → Bobo': {'start': const Offset(100, 100), 'end': const Offset(400, 200)},
      'Bobo → Ouaga': {'start': const Offset(400, 200), 'end': const Offset(100, 100)},
      'Ouaga → Koudougou': {'start': const Offset(100, 100), 'end': const Offset(300, 300)},
      'Koudougou → Ouaga': {'start': const Offset(300, 300), 'end': const Offset(100, 100)},
    };

    for (var schedule in schedules) {
      if (routeCoordinates.containsKey(schedule.route)) {
        final coords = routeCoordinates[schedule.route]!;
        lines.add(
          CustomPaint(
            painter: _RouteLinePainter(
              start: coords['start']!,
              end: coords['end']!,
              color: DashboardTheme.primary,
            ),
            size: Size.infinite,
          ),
        );
      }
    }

    return lines;
  }

  List<Widget> _buildCityMarkers() {
    final markers = [
      // Ouagadougou
      Positioned(
        left: 80,
        top: 80,
        child: _CityMarker(
          label: 'Ouagadougou',
          isMajor: true,
          color: DashboardTheme.error,
        ),
      ),
      // Bobo-Dioulasso
      Positioned(
        right: 80,
        top: 180,
        child: _CityMarker(
          label: 'Bobo-Dioulasso',
          isMajor: true,
          color: DashboardTheme.error,
        ),
      ),
      // Koudougou
      Positioned(
        left: 280,
        bottom: 80,
        child: _CityMarker(
          label: 'Koudougou',
          isMajor: true,
          color: DashboardTheme.error,
        ),
      ),
      // Bus stops along routes
      Positioned(
        left: 250,
        top: 150,
        child: _CityMarker(
          label: 'Stop 1',
          isMajor: false,
          color: DashboardTheme.warning,
        ),
      ),
      Positioned(
        left: 200,
        bottom: 200,
        child: _CityMarker(
          label: 'Stop 2',
          isMajor: false,
          color: DashboardTheme.warning,
        ),
      ),
    ];

    return markers;
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[100]!
      ..strokeWidth = 0.5;

    // Draw grid lines
    for (double i = 0; i <= size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.blue[300]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RouteLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  _RouteLinePainter({required this.start, required this.end, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw the main route line
    canvas.drawLine(start, end, paint);

    // Draw arrow in the middle to show direction
    final midPoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowLength = 10;
    
    final arrow1 = Offset(
      midPoint.dx - arrowLength * cos(angle - 0.5),
      midPoint.dy - arrowLength * sin(angle - 0.5),
    );
    
    final arrow2 = Offset(
      midPoint.dx - arrowLength * cos(angle + 0.5),
      midPoint.dy - arrowLength * sin(angle + 0.5),
    );
    
    canvas.drawLine(midPoint, arrow1, paint..strokeWidth = 2);
    canvas.drawLine(midPoint, arrow2, paint..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CityMarker extends StatelessWidget {
  final String label;
  final bool isMajor;
  final Color color;

  const _CityMarker({
    required this.label,
    required this.isMajor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMajor ? Icons.location_on : Icons.location_on_outlined,
          color: color,
          size: isMajor ? 24 : 18,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: DashboardTheme.labelSmall.copyWith(
              color: color,
              fontWeight: isMajor ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
