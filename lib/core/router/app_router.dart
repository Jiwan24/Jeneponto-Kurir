import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/delivery/presentation/customer/pages/courier_searching_page.dart';
import '../../features/delivery/presentation/customer/pages/delivery_detail_page.dart';
import '../../features/delivery/presentation/customer/pages/delivery_history_page.dart';
import '../../features/delivery/presentation/customer/pages/map_picker_page.dart';
import '../../features/delivery/presentation/customer/pages/search_courier_page.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/order/presentation/pages/create_order_page.dart';
import '../../features/order/presentation/pages/orders_page.dart';
import '../../features/payments/presentation/pages/payment_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import 'app_paths.dart';
import 'go_router_refresh_stream.dart';

/// Routing aplikasi + guard autentikasi berdasarkan [AuthBloc].
class AppRouter {
  AppRouter(this.authBloc);

  final AuthBloc authBloc;

  static const String splashPath = '/splash';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String homePath = AppPaths.home;
  static const String ordersPath = '/orders';
  static const String createOrderPath = '/orders/create';

  late final GoRouter router = GoRouter(
    initialLocation: splashPath,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: _redirect,
    routes: [
      GoRoute(
          path: splashPath, builder: (context, state) => const SplashPage()),
      GoRoute(path: loginPath, builder: (context, state) => const LoginPage()),
      GoRoute(
          path: registerPath,
          builder: (context, state) => const RegisterPage()),
      GoRoute(path: homePath, builder: (context, state) => const HomeShell()),
      GoRoute(
          path: ordersPath, builder: (context, state) => const OrdersPage()),
      GoRoute(
        path: createOrderPath,
        builder: (context, state) => const CreateOrderPage(),
      ),
      // ---- Delivery / pembayaran / dompet (Person 2) ----
      // Route statis harus dideklarasikan sebelum `/delivery/:id`.
      GoRoute(
        path: AppPaths.deliveryNew,
        builder: (context, state) => const SearchCourierPage(),
      ),
      GoRoute(
        path: AppPaths.deliveryHistory,
        builder: (context, state) => const DeliveryHistoryPage(),
      ),
      GoRoute(
        path: AppPaths.deliveryPickLocation,
        builder: (context, state) {
          final Object? extra = state.extra;
          return MapPickerPage(
            args: extra is MapPickerArgs ? extra : null,
          );
        },
      ),
      GoRoute(
        path: AppPaths.wallet,
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: '/delivery/:id/searching',
        builder: (context, state) => CourierSearchingPage(
          orderId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/delivery/:id/payment',
        builder: (context, state) => PaymentPage(
          orderId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/delivery/:id',
        builder: (context, state) => DeliveryDetailPage(
          orderId: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final AuthStatus status = authBloc.state.status;
    final String location = state.matchedLocation;
    final bool isAuthRoute = location == loginPath || location == registerPath;
    final bool isSplash = location == splashPath;

    switch (status) {
      case AuthStatus.initial:
        // Masih menentukan status login awal -> paksa splash.
        return isSplash ? null : splashPath;
      case AuthStatus.loading:
        // Biarkan halaman saat ini menampilkan indikator loading
        // (mis. saat menekan tombol "Masuk").
        return null;
      case AuthStatus.authenticated:
        if (isSplash || isAuthRoute) return homePath;
        return null;
      case AuthStatus.unauthenticated:
      case AuthStatus.failure:
        return isAuthRoute ? null : loginPath;
    }
  }
}
