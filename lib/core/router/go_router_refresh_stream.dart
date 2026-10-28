import 'dart:async';

import 'package:flutter/foundation.dart';

/// Menjembatani stream (mis. AuthBloc.stream) ke [Listenable] GoRouter,
/// sehingga setiap perubahan status auth memicu evaluasi redirect ulang.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
