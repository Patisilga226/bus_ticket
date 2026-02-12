import 'package:flutter/material.dart';
import '../themes/dashboard_theme.dart';

class StatCardData {
  final String title;
  final String value;
  final String subtitle;
  final double trend;
  final Color accentColor;
  final IconData icon;
  final String? prefix;
  final String? suffix;

  const StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trend,
    required this.accentColor,
    required this.icon,
    this.prefix,
    this.suffix,
  });
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.data});

  final StatCardData data;

  @override
  Widget build(BuildContext context) {
    final isPositive = data.trend >= 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DashboardTheme.radiusXl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.accentColor.withOpacity(0.12),
            Colors.white.withOpacity(0.95),
          ],
        ),
        border: Border.all(
          color: data.accentColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: data.accentColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DashboardTheme.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: DashboardTheme.bodySmall.copyWith(
                        color: DashboardTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DashboardTheme.radiusLg),
                      gradient: LinearGradient(
                        colors: [
                          data.accentColor.withOpacity(0.2),
                          data.accentColor.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      data.icon,
                      color: data.accentColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Main value display
              Text.rich(
                TextSpan(
                  children: [
                    if (data.prefix != null)
                      TextSpan(
                        text: data.prefix,
                        style: DashboardTheme.labelLarge.copyWith(
                          color: DashboardTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    TextSpan(
                      text: data.value,
                      style: DashboardTheme.titleLarge.copyWith(
                        color: DashboardTheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (data.suffix != null)
                      TextSpan(
                        text: data.suffix,
                        style: DashboardTheme.labelLarge.copyWith(
                          color: DashboardTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Subtitle
              Text(
                data.subtitle,
                style: DashboardTheme.labelSmall.copyWith(
                  color: DashboardTheme.onSurfaceVariant,
                ),
              ),
              
              const Spacer(),
              
              // Trend indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? DashboardTheme.success.withOpacity(0.12)
                      : DashboardTheme.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
                  border: Border.all(
                    color: isPositive
                        ? DashboardTheme.success.withOpacity(0.2)
                        : DashboardTheme.error.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: isPositive
                          ? DashboardTheme.success
                          : DashboardTheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${data.trend.toStringAsFixed(1)}%',
                      style: DashboardTheme.labelMedium.copyWith(
                        color: isPositive
                            ? DashboardTheme.success
                            : DashboardTheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

