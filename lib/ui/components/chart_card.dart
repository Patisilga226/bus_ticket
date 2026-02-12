import 'package:flutter/material.dart';
import '../themes/dashboard_theme.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final List<ChartLegendItem>? legendItems;
  final VoidCallback? onSeeAllPressed;
  final double height;
  final EdgeInsets? padding;

  const ChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.subtitle,
    this.legendItems,
    this.onSeeAllPressed,
    this.height = 300,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashboardTheme.cardDecoration,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DashboardTheme.titleMedium.copyWith(
                          color: DashboardTheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: DashboardTheme.bodySmall.copyWith(
                            color: DashboardTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onSeeAllPressed != null)
                  TextButton(
                    onPressed: onSeeAllPressed,
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
            
            // Chart
            SizedBox(
              height: height,
              child: chart,
            ),
            
            // Legend
            if (legendItems != null && legendItems!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: legendItems!
                    .map((item) => _LegendItem(item: item))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ChartLegendItem {
  final Color color;
  final String label;
  final String value;
  final double? percentage;
  final IconData? icon;

  const ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
    this.percentage,
    this.icon,
  });
}

class _LegendItem extends StatelessWidget {
  final ChartLegendItem item;

  const _LegendItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.label,
          style: DashboardTheme.labelMedium.copyWith(
            color: DashboardTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          item.value,
          style: DashboardTheme.labelMedium.copyWith(
            color: DashboardTheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (item.percentage != null) ...[
          const SizedBox(width: 4),
          Text(
            '(${item.percentage!.toStringAsFixed(1)}%)',
            style: DashboardTheme.labelSmall.copyWith(
              color: DashboardTheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}