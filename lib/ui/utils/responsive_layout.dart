import 'package:flutter/material.dart';

/// Responsive layout utilities for adaptive dashboard design
class ResponsiveLayout {
  /// Breakpoint constants
  static const double mobileMax = 768;
  static const double tabletMax = 1024;
  static const double desktopMin = 1025;
  
  /// Get responsive grid column count
  static int getColumnCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    
    if (width <= mobileMax) {
      return 1; // Mobile: single column
    } else if (width <= tabletMax) {
      return 2; // Tablet: two columns
    } else {
      return 4; // Desktop: four columns
    }
  }
  
  /// Get responsive spacing based on screen size
  static double getSpacing(BuildContext context, {double? mobile, double? tablet, double? desktop}) {
    final width = MediaQuery.sizeOf(context).width;
    
    if (width <= mobileMax) {
      return mobile ?? 16.0;
    } else if (width <= tabletMax) {
      return tablet ?? 20.0;
    } else {
      return desktop ?? 24.0;
    }
  }
  
  /// Get responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    
    if (width <= mobileMax) {
      return const EdgeInsets.all(16.0);
    } else if (width <= tabletMax) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }
  
  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width <= mobileMax;
  }
  
  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > mobileMax && width <= tabletMax;
  }
  
  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width > tabletMax;
  }
  
  /// Get responsive text scale factor
  static double getTextScale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    
    if (width <= mobileMax) {
      return 1.0;
    } else if (width <= tabletMax) {
      return 1.1;
    } else {
      return 1.2;
    }
  }
}

/// Responsive grid widget for dashboard cards
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 20.0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });
  
  @override
  Widget build(BuildContext context) {
    final columnCount = ResponsiveLayout.getColumnCount(context);
    
    if (columnCount == 1) {
      // Mobile: Vertical layout
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    } else {
      // Tablet/Desktop: Grid layout
      return GridView.count(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      );
    }
  }
}

/// Responsive row that adapts to screen size
class AdaptiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  
  const AdaptiveRow({
    super.key,
    required this.children,
    this.spacing = 20.0,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) SizedBox(width: spacing),
          ],
        ],
      );
    }
  }
}