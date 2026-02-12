import 'package:flutter/material.dart';

/// Design tokens and theme configuration for the dashboard
class DashboardTheme {
  // Primary Colors
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4338CA);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFEC4899);
  static const Color secondaryLight = Color(0xFFF472B6);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const Color background = Color(0xFFF9FAFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  static const Color outline = Color(0xFFE5E7EB);
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF4F46E5),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
  ];
  
  // Spacing System (8px grid)
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  
  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;
  
  // Elevations
  static const double elevationSm = 2.0;
  static const double elevationMd = 6.0;
  static const double elevationLg = 12.0;
  
  // Typography
  static TextStyle headlineSmall = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  
  static TextStyle titleLarge = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle titleMedium = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle bodyMedium = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle bodySmall = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static TextStyle labelLarge = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  
  static TextStyle labelMedium = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  
  static TextStyle labelSmall = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  
  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusXl),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
  
  static BoxDecoration cardGlassDecoration = BoxDecoration(
    color: surface.withOpacity(0.85),
    borderRadius: BorderRadius.circular(radiusXl),
    border: Border.all(
      color: outline.withOpacity(0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // Gradient Backgrounds
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient secondaryGradient = const LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Responsive Breakpoints
  static const double mobileMax = 768;
  static const double tabletMax = 1024;
  static const double desktopMin = 1025;
}

/// Extension to easily apply dashboard theme to widgets
extension DashboardThemeExtensions on BuildContext {
  bool get isMobile => MediaQuery.sizeOf(this).width <= DashboardTheme.mobileMax;
  bool get isTablet => MediaQuery.sizeOf(this).width > DashboardTheme.mobileMax && 
                      MediaQuery.sizeOf(this).width <= DashboardTheme.tabletMax;
  bool get isDesktop => MediaQuery.sizeOf(this).width > DashboardTheme.tabletMax;
  
  double get responsivePadding => isMobile 
      ? DashboardTheme.spacingMd 
      : isTablet 
          ? DashboardTheme.spacingLg 
          : DashboardTheme.spacingXl;
}