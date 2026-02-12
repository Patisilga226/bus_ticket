import 'package:flutter/material.dart';
import '../themes/dashboard_theme.dart';

enum BookingStatus { confirmed, pending, cancelled }

class RecentBooking {
  final String id;
  final String passenger;
  final String route;
  final String date;
  final BookingStatus status;
  final String amount;

  const RecentBooking({
    required this.id,
    required this.passenger,
    required this.route,
    required this.date,
    required this.status,
    required this.amount,
  });
}

class RecentBookingTile extends StatelessWidget {
  const RecentBookingTile({super.key, required this.booking});

  final RecentBooking booking;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label, icon, iconColor) = switch (booking.status) {
      BookingStatus.confirmed => (
          DashboardTheme.success.withOpacity(0.12),
          DashboardTheme.success,
          'Confirmé',
          Icons.check_circle_rounded,
          DashboardTheme.success,
        ),
      BookingStatus.pending => (
          DashboardTheme.warning.withOpacity(0.12),
          DashboardTheme.warning,
          'En attente',
          Icons.access_time_rounded,
          DashboardTheme.warning,
        ),
      BookingStatus.cancelled => (
          DashboardTheme.error.withOpacity(0.12),
          DashboardTheme.error,
          'Annulé',
          Icons.cancel_rounded,
          DashboardTheme.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardTheme.surface,
        borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
        border: Border.all(
          color: DashboardTheme.outline,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(DashboardTheme.radiusMd),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.passenger,
                  style: DashboardTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DashboardTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.route} • ${booking.date}',
                  style: DashboardTheme.labelSmall.copyWith(
                    color: DashboardTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                booking.amount,
                style: DashboardTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DashboardTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
                  border: Border.all(
                    color: fg.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  label,
                  style: DashboardTheme.labelSmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

