import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../widgets/stat_card.dart';
import '../widgets/recent_booking_tile.dart';
import '../components/chart_card.dart';
import '../components/filter_chip.dart';
import '../themes/dashboard_theme.dart';
import '../utils/responsive_layout.dart';
import 'tickets_page.dart';
import 'buses_page.dart';
import 'schedules_page.dart';
import 'drivers_page.dart';

class DashboardPage extends StatefulWidget {
  final void Function(int) onNavigateToPage;
  
  const DashboardPage({super.key, required this.onNavigateToPage});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTimeRange? _selectedDateRange;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
  
  // Button action methods
  void _addNewTicket() {
    widget.onNavigateToPage(1); // Tickets
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigué vers la gestion des tickets'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _addNewBus() {
    widget.onNavigateToPage(2); // Buses
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigué vers la gestion des bus'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonction d\'importation en cours de développement'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _addNewSchedule() {
    widget.onNavigateToPage(3); // Schedules
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigué vers la gestion des horaires'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _viewOnMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Affichage de la carte en cours de développement'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  void _addNewDriver() {
    widget.onNavigateToPage(4); // Drivers
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigué vers la gestion des chauffeurs'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  void _importSheets() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Importation des fiches en cours de développement'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewAllPopularRoutes() {
    widget.onNavigateToPage(3); // Horaires
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture de la page Horaires'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _viewAllRecentBookings() {
    widget.onNavigateToPage(1); // Tickets
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture de la page Tickets'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    final frenchMonths = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final frenchDays = [
      'dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'
    ];
    
    final dayName = frenchDays[now.weekday % 7];
    final monthName = frenchMonths[now.month - 1];
    
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      StatCardData(
        title: 'Revenu total',
        value: '612 317',
        subtitle: 'Mois en cours',
        trend: 12.5,
        accentColor: DashboardTheme.primary,
        icon: Icons.account_balance_wallet_rounded,
        prefix: '',
        suffix: ' FCFA',
      ),
      StatCardData(
        title: 'Réservations',
        value: '34 760',
        subtitle: 'Total ce mois',
        trend: 8.2,
        accentColor: DashboardTheme.success,
        icon: Icons.confirmation_number_rounded,
        prefix: '',
        suffix: '',
      ),
      StatCardData(
        title: 'Passagers',
        value: '14 987',
        subtitle: 'Actifs ce mois',
        trend: -2.4,
        accentColor: DashboardTheme.warning,
        icon: Icons.people_rounded,
        prefix: '',
        suffix: '',
      ),
      StatCardData(
        title: 'Bus actifs',
        value: '42',
        subtitle: 'En service',
        trend: 5.0,
        accentColor: DashboardTheme.info,
        icon: Icons.directions_bus_filled_rounded,
        prefix: '',
        suffix: '',
      ),
    ];

    final bookings = [
      const RecentBooking(
        id: 'BK-001',
        passenger: 'Amadou Traoré',
        route: 'Ouaga → Bobo',
        date: '27 Jan 2025',
        status: BookingStatus.confirmed,
        amount: '5 000 FCFA',
      ),
      const RecentBooking(
        id: 'BK-002',
        passenger: 'Fatima Sawadogo',
        route: 'Bobo → Ouaga',
        date: '27 Jan 2025',
        status: BookingStatus.pending,
        amount: '5 000 FCFA',
      ),
      const RecentBooking(
        id: 'BK-003',
        passenger: 'Ibrahim Ouédraogo',
        route: 'Ouaga → Koudougou',
        date: '26 Jan 2025',
        status: BookingStatus.confirmed,
        amount: '3 500 FCFA',
      ),
      const RecentBooking(
        id: 'BK-004',
        passenger: 'Mariam Compaoré',
        route: 'Koudougou → Ouaga',
        date: '26 Jan 2025',
        status: BookingStatus.cancelled,
        amount: '3 500 FCFA',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: ResponsiveLayout.getPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(context),
              const SizedBox(height: 32),

              // Quick Action Buttons
              _buildQuickActions(),
              const SizedBox(height: 32),
              
              // Statistics Cards
              ResponsiveGrid(
                children: stats.map((stat) => StatCard(data: stat)).toList(),
                spacing: 24,
              ),
              const SizedBox(height: 32),

              // Charts Section
              AdaptiveRow(
                children: [
                  _RevenueChartCard(),
                  _BusTypeCard(),
                ],
                spacing: 24,
              ),
              const SizedBox(height: 32),

              // Bottom Section
              AdaptiveRow(
                children: [
                  _PopularRoutesCard(onSeeAll: _viewAllPopularRoutes),
                  _RecentBookingsCard(
                    bookings: bookings,
                    onSeeAll: _viewAllRecentBookings,
                  ),
                ],
                spacing: 24,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tableau de bord',
                style: DashboardTheme.headlineSmall.copyWith(
                  color: DashboardTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrentDate(),
                style: DashboardTheme.bodyMedium.copyWith(
                  color: DashboardTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!ResponsiveLayout.isMobile(context))
          DateFilterChip(
            label: 'Ce mois',
            startDate: _selectedDateRange?.start,
            endDate: _selectedDateRange?.end,
            onDateRangeSelected: (range) {
              setState(() {
                _selectedDateRange = range;
              });
            },
          ),
      ],
    );
  }
  
  Widget _buildQuickActions() {
    return Container(
      decoration: DashboardTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: DashboardTheme.titleMedium.copyWith(
                color: DashboardTheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Ajouter un nouveau ticket
                FilledButton.icon(
                  onPressed: _addNewTicket,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: DashboardTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
                    ),
                  ),
                  icon: Icon(
                    Icons.confirmation_number_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Ajouter un nouveau ticket',
                    style: DashboardTheme.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Ajouter un nouveau bus
                FilledButton.icon(
                  onPressed: _addNewBus,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: DashboardTheme.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
                    ),
                  ),
                  icon: Icon(
                    Icons.directions_bus_filled_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Ajouter un nouveau bus',
                    style: DashboardTheme.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Importer
                OutlinedButton.icon(
                  onPressed: _importData,
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
                    Icons.upload_rounded,
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
                
                // Nouvel horaire
                FilledButton.icon(
                  onPressed: _addNewSchedule,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: DashboardTheme.warning,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
                    ),
                  ),
                  icon: Icon(
                    Icons.schedule_rounded,
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
                
                // Voir sur la carte
                OutlinedButton.icon(
                  onPressed: _viewOnMap,
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
                    Icons.map_rounded,
                    size: 20,
                    color: DashboardTheme.info,
                  ),
                  label: Text(
                    'Voir sur la carte',
                    style: DashboardTheme.labelMedium.copyWith(
                      color: DashboardTheme.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                // Nouveau chauffeur
                FilledButton.icon(
                  onPressed: _addNewDriver,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: DashboardTheme.info,
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
                
                // Importer les fiches
                OutlinedButton.icon(
                  onPressed: _importSheets,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: BorderSide(
                      color: DashboardTheme.success.withOpacity(0.3),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
                    ),
                  ),
                  icon: Icon(
                    Icons.file_download_rounded,
                    size: 20,
                    color: DashboardTheme.success,
                  ),
                  label: Text(
                    'Importer les fiches',
                    style: DashboardTheme.labelMedium.copyWith(
                      color: DashboardTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: 'Activité des réservations',
      subtitle: "Vue d'ensemble mensuelle",
      height: 300,
      chart: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) => FlLine(
              color: DashboardTheme.outline,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}k',
                    style: DashboardTheme.labelSmall.copyWith(
                      color: DashboardTheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  const labels = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul'];
                  if (value.toInt() < 0 || value.toInt() >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[value.toInt()],
                      style: DashboardTheme.labelSmall.copyWith(
                        color: DashboardTheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 20,
          maxY: 90,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 40),
                FlSpot(1, 35),
                FlSpot(2, 55),
                FlSpot(3, 50),
                FlSpot(4, 70),
                FlSpot(5, 80),
                FlSpot(6, 65),
              ],
              isCurved: true,
              gradient: DashboardTheme.primaryGradient,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 6,
                  color: DashboardTheme.primary,
                  strokeWidth: 3,
                  strokeColor: DashboardTheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    DashboardTheme.primary.withOpacity(0.2),
                    DashboardTheme.primary.withOpacity(0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusTypeCard extends StatefulWidget {
  @override
  State<_BusTypeCard> createState() => _BusTypeCardState();
}

class _BusTypeCardState extends State<_BusTypeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DashboardTheme.chartColors;
    final data = [
      {'label': 'Bus VIP', 'value': 45.0, 'color': colors[0]},
      {'label': 'Bus Standard', 'value': 35.0, 'color': colors[1]},
      {'label': 'Bus Éco', 'value': 20.0, 'color': colors[2]},
    ];

    return ChartCard(
      title: 'Répartition par type',
      subtitle: 'Distribution des bus',
      height: 280,
      legendItems: data
          .map((item) => ChartLegendItem(
                color: item['color'] as Color,
                label: item['label'] as String,
                value: '${(item['value'] as double).toInt()}%',
              ))
          .toList(),
      chart: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          final t = _rotationController.value * 2 * math.pi;
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 50 + 10 * math.sin(t),
                sectionsSpace: 3,
                sections: data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final pulse = 62 + 16 * math.sin(t + index * 1.8);
                  return PieChartSectionData(
                    color: item['color'] as Color,
                    value: item['value'] as double,
                    radius: pulse,
                    title: '${(item['value'] as double).toInt()}%',
                    titleStyle: DashboardTheme.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }
}

class _PopularRoutesCard extends StatelessWidget {
  const _PopularRoutesCard({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final routes = [
      _PopularRoute('Ouaga - Bobo', 2487, 32),
      _PopularRoute('Bobo - Ouaga', 1823, 24),
      _PopularRoute('Ouaga - Koudougou', 1428, 18),
      _PopularRoute('Koudougou - Ouaga', 1243, 16),
      _PopularRoute('Autres', 779, 10),
    ];

    return Container(
      decoration: DashboardTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trajets populaires',
                        style: DashboardTheme.titleMedium.copyWith(
                          color: DashboardTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Top 5 des routes',
                        style: DashboardTheme.bodySmall.copyWith(
                          color: DashboardTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'Voir tout',
                    style: DashboardTheme.labelMedium.copyWith(
                      color: DashboardTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: routes.asMap().entries.map((entry) {
                final index = entry.key;
                final route = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: DashboardTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: DashboardTheme.labelMedium.copyWith(
                              color: DashboardTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    route.name,
                                    style: DashboardTheme.bodyMedium.copyWith(
                                      color: DashboardTheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${route.bookings}',
                                  style: DashboardTheme.bodyMedium.copyWith(
                                    color: DashboardTheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: route.percent / 100,
                                minHeight: 6,
                                backgroundColor: DashboardTheme.outline,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  DashboardTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularRoute {
  final String name;
  final int bookings;
  final double percent;

  _PopularRoute(this.name, this.bookings, this.percent);
}

class _RecentBookingsCard extends StatelessWidget {
  const _RecentBookingsCard({
    required this.bookings,
    required this.onSeeAll,
  });

  final List<RecentBooking> bookings;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashboardTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réservations récentes',
                        style: DashboardTheme.titleMedium.copyWith(
                          color: DashboardTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dernières transactions',
                        style: DashboardTheme.bodySmall.copyWith(
                          color: DashboardTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'Voir tout',
                    style: DashboardTheme.labelMedium.copyWith(
                      color: DashboardTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              children: bookings.map((booking) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: RecentBookingTile(booking: booking),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
