import 'package:flutter/material.dart';
import '../themes/dashboard_theme.dart';

class FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? selectedColor;
  final Color? unselectedColor;

  const FilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onPressed,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBgColor = selectedColor ?? DashboardTheme.primary.withOpacity(0.12);
    final unselectedBgColor = unselectedColor ?? DashboardTheme.surfaceVariant;
    final selectedTextColor = selectedColor ?? DashboardTheme.primary;
    final unselectedTextColor = DashboardTheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : unselectedBgColor,
          borderRadius: BorderRadius.circular(DashboardTheme.radiusFull),
          border: Border.all(
            color: isSelected 
                ? selectedTextColor.withOpacity(0.3) 
                : DashboardTheme.outline,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? selectedTextColor : unselectedTextColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: DashboardTheme.labelMedium.copyWith(
                color: isSelected ? selectedTextColor : unselectedTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: selectedTextColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DateFilterChip extends StatefulWidget {
  final String label;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTimeRange?> onDateRangeSelected;

  const DateFilterChip({
    super.key,
    required this.label,
    this.startDate,
    this.endDate,
    required this.onDateRangeSelected,
  });

  @override
  State<DateFilterChip> createState() => _DateFilterChipState();
}

class _DateFilterChipState extends State<DateFilterChip> {
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: widget.label,
      isSelected: widget.startDate != null && widget.endDate != null,
      icon: Icons.calendar_today_outlined,
      onPressed: () async {
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          initialDateRange: widget.startDate != null && widget.endDate != null
              ? DateTimeRange(start: widget.startDate!, end: widget.endDate!)
              : null,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: DashboardTheme.primary,
                  onPrimary: Colors.white,
                  surface: DashboardTheme.surface,
                  onSurface: DashboardTheme.onSurface,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          widget.onDateRangeSelected(picked);
        }
      },
    );
  }
}