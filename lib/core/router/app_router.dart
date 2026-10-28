import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/courier/presentation/pages/courier_dashboard_page.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/order/presentation/pages/create_order_page.dart';
import '../../features/order/presentation/pages/orders_page.dart';
import '../../features/splash/presentation/splash_page.dart';
import 'go_router_refresh_stream.dart';

/// Routing aplikasi + guard autentikasi berdasarkan [AuthBloc].
class AppRouter {
  AppRouter(this.authBloc);

  final AuthBloc authBloc;

  static const String splashPath = '/splash';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String homePath = '/home';
  static const String ordersPath = '/orders';
  static const String createOrderPath = '/orders/create';

  late final GoRouter router = GoRouter(
    initialLocation: splashPath,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: _redirect,
    routes: [
      GoRoute(path: splashPath, builder: (context, state) => const SplashPage()),
      GoRoute(path: loginPath, builder: (context, state) => const LoginPage()),
      GoRoute(path: registerPath, builder: (context, state) => const RegisterPage()),
      GoRoute(path: homePath, builder: (context, state) => const HomeShell()),
      GoRoute(path: ordersPath, builder: (context, state) => const OrdersPage()),
      GoRoute(
        path: createOrderPath,
        builder: (context, state) => const CreateOrderPage(),
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final AuthStatus status = authBloc.state.status;
    final String location = state.matchedLocation;
    final bool isAuthRoute =
        location == loginPath || location == registerPath;
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
