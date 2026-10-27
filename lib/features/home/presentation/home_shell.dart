import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../admin/presentation/pages/admin_dashboard_page.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../courier/presentation/pages/courier_dashboard_page.dart';
import '../../delivery/presentation/customer/pages/delivery_history_page.dart';
import '../../delivery/presentation/customer/pages/search_courier_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
import 'pages/customer_home_page.dart';

/// Shell utama setelah login: bottom navigation menyesuaikan peran.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) {
      // Sedang dialihkan oleh router; tampilkan indikator singkat.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final destinations = _destinationsFor(user.role);
    final int index = _selectedIndex < destinations.length ? _selectedIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: [for (final d in destinations) d.page],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => _selectedIndex = value);
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }

  List<_ShellDestination> _destinationsFor(UserRole role) {
    const profile = _ShellDestination(
      label: 'Profil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      page: ProfilePage(),
    );

    switch (role) {
      case UserRole.customer:
        return const [
          _ShellDestination(
            label: 'Beranda',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            page: CustomerHomePage(),
          ),
          _ShellDestination(
            label: 'Cari Kurir',
            icon: Icons.local_shipping_outlined,
            selectedIcon: Icons.local_shipping,
            page: SearchCourierPage(embedded: true),
          ),
          _ShellDestination(
            label: 'Pesanan',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            page: DeliveryHistoryPage(),
          ),
          profile,
        ];
      case UserRole.courier:
        return const [
          _ShellDestination(
            label: 'Order',
            icon: Icons.local_shipping_outlined,
            selectedIcon: Icons.local_shipping,
            page: CourierDashboardPage(),
          ),
          profile,
        ];
      case UserRole.admin:
        return const [
          _ShellDestination(
            label: 'Dashboard',
            icon: Icons.space_dashboard_outlined,
            selectedIcon: Icons.space_dashboard,
            page: AdminDashboardPage(),
          ),
          profile,
        ];
    }
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}
