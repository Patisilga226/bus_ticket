import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';
import 'pages/tickets_page.dart';
import 'pages/buses_page.dart';
import 'pages/schedules_page.dart';
import 'pages/drivers_page.dart';
import 'pages/passengers_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isMobile = constraints.maxWidth < 640;
        final outerPadding = isMobile ? 12.0 : 24.0;
        final innerPadding = isMobile ? 12.0 : 24.0;
        final contentRadius = isMobile ? 20.0 : 32.0;

        final pages = [
          DashboardPage(onNavigateToPage: (index) {
            print('DEBUG: DashboardShell received navigation request to index: $index');
            setState(() => _selectedIndex = index);
            print('DEBUG: DashboardShell state updated, selectedIndex: $_selectedIndex');
          }),
          const TicketsPage(),
          const BusesPage(),
          const SchedulesPage(),
          const DriversPage(),
          const PassengersPage(),
          const ReportsPage(),
          const SettingsPage(),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7F5),
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  _SideNav(
                    selectedIndex: _selectedIndex,
                    onItemSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(colorScheme: colorScheme, isDesktop: isDesktop),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(outerPadding),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(contentRadius),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFF9FAFF),
                                    Color(0xFFF1F4FF),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(innerPadding),
                                child: pages[_selectedIndex],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          drawer: isDesktop
              ? null
              : Drawer(
                  child: _SideNav(
                    selectedIndex: _selectedIndex,
                    onItemSelected: (index) {
                      setState(() => _selectedIndex = index);
                      Navigator.of(context).maybePop();
                    },
                  ),
                ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.colorScheme,
    required this.isDesktop,
  });

  final ColorScheme colorScheme;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 640;

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            Expanded(
              child: Text(
                'DealDeck Bus',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
              ),
            ),
            const SizedBox(width: 6),
            const _CircleIcon(icon: Icons.notifications_none_rounded),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          if (isDesktop)
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4F46E5),
                        Color(0xFF6366F1),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_bus_filled_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DealDeck Bus',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    Text(
                      "Tableau de bord d'administration",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF94A3B8),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rechercher',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
                const SizedBox(width: 24),
                const _CircleIcon(icon: Icons.notifications_none_rounded),
                const SizedBox(width: 12),
                const _CircleIcon(icon: Icons.settings_outlined),
                const SizedBox(width: 16),
                const _UserChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(
        icon,
        size: 18,
        color: const Color(0xFF6B7280),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFFEC4899),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'FA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ferra Alexandra',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              Text(
                'Admin',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      const _NavItem(Icons.dashboard_rounded, 'Dashboard'),
      const _NavItem(Icons.confirmation_num_outlined, 'Tickets'),
      const _NavItem(Icons.directions_bus_filled_outlined, 'Bus'),
      const _NavItem(Icons.schedule_rounded, 'Horaires'),
      const _NavItem(Icons.person_outline_rounded, 'Chauffeurs'),
      const _NavItem(Icons.people_outline_rounded, 'Passagers'),
      const _NavItem(Icons.insert_chart_outlined_rounded, 'Rapports'),
      const _NavItem(Icons.settings_outlined, 'Paramètres'),
    ];

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;
                return _SideNavTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onItemSelected(index),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFF6366F1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade Pro',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rapports avancés & prévisions de trafic.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mettre à niveau',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

class _SideNavTile extends StatelessWidget {
  const _SideNavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.white : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? const Color(0xFFEEF2FF)
                    : const Color(0xFFE5E7EB),
              ),
              child: Icon(
                item.icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF111827)
                        : const Color(0xFF6B7280),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
