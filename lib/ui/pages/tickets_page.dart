import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/ticket.dart';
import '../themes/dashboard_theme.dart';
import '../utils/responsive_layout.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Ticket? _lastCreatedTicket;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final ticketsData = await _apiService.getTickets();
      setState(() {
        _tickets = ticketsData.map((data) => Ticket.fromJson(data)).toList();
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

  Future<void> _addNewTicket() async {
    final formKey = GlobalKey<FormState>();
    final passengerCtrl = TextEditingController();
    final routeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String status = 'Pending';
    
    final result = await showDialog<Map<String, dynamic>?> (
      context: context,
      builder: (context) {
        final isMobile = ResponsiveLayout.isMobile(context);
        return AlertDialog(
          title: const Text('Nouveau Ticket'),
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
                      controller: passengerCtrl,
                      decoration: const InputDecoration(labelText: 'Nom du passager'),
                      validator: (value) => value?.trim().isEmpty == true ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: routeCtrl,
                      decoration: const InputDecoration(labelText: 'Trajet'),
                      validator: (value) => value?.trim().isEmpty == true ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Montant invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: const [
                        DropdownMenuItem(value: 'Pending', child: Text('En attente')),
                        DropdownMenuItem(value: 'Confirmed', child: Text('Confirmé')),
                        DropdownMenuItem(value: 'Cancelled', child: Text('Annulé')),
                      ],
                      onChanged: (value) => status = value ?? 'Pending',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'passengerName': passengerCtrl.text.trim(),
                    'route': routeCtrl.text.trim(),
                    'amount': int.parse(amountCtrl.text.trim()),
                    'status': status,
                    'date': DateTime.now().toString().split('T')[0],
                  });
                }
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
    
    if (result != null) {
      try {
        final resolvedBusId = await _resolveBusIdForRoute(result['route']?.toString() ?? '');

        if (resolvedBusId == null) {
          throw Exception('Aucun bus disponible pour créer ce ticket');
        }

        // Transform form data to match API expectations
        final ticketData = {
          'passengerName': result['passengerName'],
          'route': result['route'],
          'amount': result['amount'],
          'status': result['status'],
          'busId': resolvedBusId,
          'seatNumber': null, // Let API auto-assign seat
        };
        
        final created = Ticket.fromJson(await _apiService.createTicket(ticketData));
        await _loadTickets();
        if (!mounted) return;
        setState(() {
          _lastCreatedTicket = created;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket #${created.id} créé avec succès'),
            backgroundColor: DashboardTheme.success,
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () => _showTicketDetailsDialog(created),
            ),
          ),
        );
      } catch (e) {
        print('Error creating ticket: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: DashboardTheme.error),
        );
      }
    }
  }

  Future<int?> _resolveBusIdForRoute(String routeInput) async {
    final buses = await _apiService.getBuses();
    if (buses.isEmpty) return null;

    final now = DateTime.now();
    final normalizedRoute = routeInput.trim().toLowerCase();

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    bool hasSeats(Map<String, dynamic> bus) {
      final available = parseInt(bus['available_seats']) ?? 0;
      return available > 0;
    }

    bool isFuture(Map<String, dynamic> bus) {
      final departure = parseDate(bus['departure_time']);
      if (departure == null) return true;
      return departure.isAfter(now);
    }

    Map<String, dynamic>? pickFirst(List<Map<String, dynamic>> list) {
      return list.isEmpty ? null : list.first;
    }

    final mappedBuses = buses
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final matchingRoute = mappedBuses.where((bus) {
      final route = (bus['route'] ?? '').toString().toLowerCase();
      return normalizedRoute.isNotEmpty && route.contains(normalizedRoute);
    }).toList();

    final preferred =
        pickFirst(matchingRoute.where((bus) => hasSeats(bus) && isFuture(bus)).toList()) ??
        pickFirst(mappedBuses.where((bus) => hasSeats(bus) && isFuture(bus)).toList()) ??
        pickFirst(matchingRoute.where(hasSeats).toList()) ??
        pickFirst(mappedBuses.where(hasSeats).toList()) ??
        pickFirst(matchingRoute) ??
        pickFirst(mappedBuses);

    return preferred == null ? null : parseInt(preferred['id']);
  }

  void _viewTicketDetails(String ticketId) {
    Ticket? ticket;
    for (final t in _tickets) {
      if (t.id.toString() == ticketId) {
        ticket = t;
        break;
      }
    }
    if (ticket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket introuvable')),
      );
      return;
    }
    _showTicketDetailsDialog(ticket);
  }

  void _showTicketDetailsDialog(Ticket ticket) {
    final isMobile = ResponsiveLayout.isMobile(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket #${ticket.id}'),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: 24,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Passager', ticket.userName),
                _detailRow('Email', ticket.userEmail),
                _detailRow('Bus', ticket.busNumber),
                _detailRow('Trajet', ticket.route),
                _detailRow('Siège', ticket.seatNumber.toString()),
                _detailRow('Prix', '${ticket.price.toStringAsFixed(0)} FCFA'),
                _detailRow('Statut', ticket.status),
                _detailRow('Départ', ticket.departureTime.toLocal().toString()),
                _detailRow('QR valide jusqu\'à', ticket.qrValidUntil.toLocal().toString()),
                _detailRow('Créé le', ticket.createdAt.toLocal().toString()),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DashboardTheme.labelMedium.copyWith(
              color: DashboardTheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DashboardTheme.bodyMedium.copyWith(
              color: DashboardTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelTicket(String ticketId) async {
    try {
      final result = await _apiService.updateTicket(ticketId, {'status': 'Cancelled'});
      setState(() {
        final index = _tickets.indexWhere((ticket) => ticket.id.toString() == ticketId);
        if (index != -1) {
          _tickets[index] = _tickets[index].copyWith(status: 'cancelled');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket $ticketId annulé'),
          backgroundColor: DashboardTheme.error,
        ),
      );
    } catch (e) {
      print('Error cancelling ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: DashboardTheme.error),
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

          if (_lastCreatedTicket != null) ...[
            _buildLastCreatedTicketCard(),
            const SizedBox(height: 24),
          ],

          // Tickets List
          _buildTicketsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion des tickets',
          style: DashboardTheme.headlineSmall.copyWith(
            color: DashboardTheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Suivez et gérez toutes les réservations et paiements.',
          style: DashboardTheme.bodyMedium.copyWith(
            color: DashboardTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final confirmed = _tickets.where((t) => t.status.toLowerCase() == 'confirmed').length;
    final pending = _tickets.where((t) => t.status.toLowerCase() == 'pending').length;
    final cancelled = _tickets.where((t) => t.status.toLowerCase() == 'cancelled').length;
    final total = _tickets.length;

    return ResponsiveGrid(
      children: [
        _TicketStatCard(
          label: 'Confirmés',
          value: '$confirmed',
          icon: Icons.check_circle_rounded,
          color: DashboardTheme.success,
          total: total,
        ),
        _TicketStatCard(
          label: 'En attente',
          value: '$pending',
          icon: Icons.access_time_rounded,
          color: DashboardTheme.warning,
          total: total,
        ),
        _TicketStatCard(
          label: 'Annulés',
          value: '$cancelled',
          icon: Icons.cancel_rounded,
          color: DashboardTheme.error,
          total: total,
        ),
        _TicketStatCard(
          label: 'Total',
          value: '$total',
          icon: Icons.confirmation_number_rounded,
          color: DashboardTheme.primary,
          total: total,
        ),
      ],
      spacing: 20,
    );
  }

  Widget _buildActionButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: _addNewTicket,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          backgroundColor: DashboardTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
          ),
        ),
        icon: Icon(
          Icons.add_rounded,
          size: 22,
          color: Colors.white,
        ),
        label: Text(
          'Nouveau ticket',
          style: DashboardTheme.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLastCreatedTicketCard() {
    final ticket = _lastCreatedTicket!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardTheme.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
        border: Border.all(
          color: DashboardTheme.success.withOpacity(0.3),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: DashboardTheme.success),
          Text(
            'Dernier ticket créé: #${ticket.id} (${ticket.route}, siège ${ticket.seatNumber})',
            style: DashboardTheme.bodyMedium.copyWith(
              color: DashboardTheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () => _showTicketDetailsDialog(ticket),
            child: const Text('Voir les détails'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList() {
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
              onPressed: _loadTickets,
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
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tickets récents',
                      style: DashboardTheme.titleMedium.copyWith(
                        color: DashboardTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_tickets.length} réservations dans le système',
                      style: DashboardTheme.bodySmall.copyWith(
                        color: DashboardTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadTickets,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualiser',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: isMobile ? 780 : 860),
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
                  DataColumn(label: Text('Passager')),
                  DataColumn(label: Text('Trajet')),
                  DataColumn(label: Text('Siège')),
                  DataColumn(label: Text('Montant')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _tickets
                    .map(
                      (ticket) => DataRow(
                        cells: [
                          DataCell(Text('${ticket.id}')),
                          DataCell(Text(ticket.userName)),
                          DataCell(Text(ticket.route)),
                          DataCell(Text('${ticket.seatNumber}')),
                          DataCell(Text('${ticket.price.toInt()} FCFA')),
                          DataCell(_TicketStatusBadge(status: ticket.status)),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Voir détails',
                                  onPressed: () => _viewTicketDetails('${ticket.id}'),
                                  icon: Icon(
                                    Icons.visibility_outlined,
                                    size: 20,
                                    color: DashboardTheme.primary,
                                  ),
                                ),
                                if (ticket.status.toLowerCase() != 'cancelled')
                                  IconButton(
                                    tooltip: 'Annuler',
                                    onPressed: () => _cancelTicket('${ticket.id}'),
                                    icon: Icon(
                                      Icons.cancel_outlined,
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
}


class _TicketStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int total;

  const _TicketStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (int.parse(value) / total * 100).toStringAsFixed(1) : '0';

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
              label,
              style: DashboardTheme.bodySmall.copyWith(
                color: DashboardTheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: DashboardTheme.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketStatusBadge extends StatelessWidget {
  const _TicketStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Confirmé':
        badgeColor = DashboardTheme.success.withOpacity(0.12);
        textColor = DashboardTheme.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'En attente':
        badgeColor = DashboardTheme.warning.withOpacity(0.12);
        textColor = DashboardTheme.warning;
        icon = Icons.access_time_rounded;
        break;
      default:
        badgeColor = DashboardTheme.error.withOpacity(0.12);
        textColor = DashboardTheme.error;
        icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: DashboardTheme.labelMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
