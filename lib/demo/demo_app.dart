import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:jeneponto_kurir/demo/demo_repositories.dart';
import 'package:jeneponto_kurir/features/common/router/app_paths.dart';
import 'package:jeneponto_kurir/features/common/theme/app_colors.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/customer/pages/courier_searching_page.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/customer/pages/delivery_detail_page.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/customer/pages/delivery_history_page.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/customer/pages/map_picker_page.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/customer/pages/search_courier_page.dart';
import 'package:jeneponto_kurir/features/payments/presentation/pages/payment_page.dart';
import 'package:jeneponto_kurir/features/wallet/presentation/pages/wallet_page.dart';

/// Aplikasi demo khusus modul Person 2.
///
/// Tidak ada auth, beranda, profil, atau fitur Person 1/3. Identitas pelanggan
/// dan kurir di-hardcode karena peran host aplikasi memang begitu di produksi.
class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Jeneponto Kurir — Demo Person 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
      ),
      routerConfig: demoRouter,
    );
  }
}

final GoRouter demoRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (_, __) => const DemoShell()),
    // Route statis harus lebih dulu dari `/delivery/:id`.
    GoRoute(
      path: AppPaths.deliveryNew,
      builder: (_, __) => const SearchCourierPage(
        customerId: demoCustomerId,
        customerName: demoCustomerName,
        customerPhone: demoCustomerPhone,
      ),
    ),
    GoRoute(
      path: AppPaths.deliveryHistory,
      builder: (_, __) => const DeliveryHistoryPage(
        customerId: demoCustomerId,
      ),
    ),
    GoRoute(
      path: AppPaths.deliveryPickLocation,
      builder: (_, GoRouterState state) {
        final Object? extra = state.extra;
        return MapPickerPage(
          args: extra is MapPickerArgs ? extra : null,
        );
      },
    ),
    GoRoute(
      path: AppPaths.wallet,
      builder: (_, __) => const WalletPage(courierId: demoCourierId),
    ),
    GoRoute(
      path: '/delivery/:id/searching',
      builder: (_, GoRouterState state) => CourierSearchingPage(
        orderId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/delivery/:id/payment',
      builder: (_, GoRouterState state) => PaymentPage(
        orderId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/delivery/:id',
      builder: (_, GoRouterState state) => DeliveryDetailPage(
        orderId: state.pathParameters['id'] ?? '',
      ),
    ),
  ],
);

/// Shell demo: tiga halaman Person 2 dalam satu bottom navigation.
class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    SearchCourierPage(
      embedded: true,
      customerId: demoCustomerId,
      customerName: demoCustomerName,
      customerPhone: demoCustomerPhone,
    ),
    DeliveryHistoryPage(customerId: demoCustomerId),
    WalletPage(courierId: demoCourierId),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: AppColors.accent,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 4,
              bottom: 4,
              left: 12,
              right: 12,
            ),
            child: const Text(
              'DEMO PERSON 2 · data lokal, tanpa login',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          // AppBar tiap halaman sudah menangani status bar sendiri bila
          // padding atas dihapus di sini.
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: IndexedStack(index: _index, children: _pages),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Kirim',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Dompet',
          ),
        ],
      ),
    );
  }
}
