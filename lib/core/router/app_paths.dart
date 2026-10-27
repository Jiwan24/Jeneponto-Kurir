/// Path route untuk modul pemesanan, pembayaran, dan dompet.
///
/// Dipisahkan dari `app_router.dart` agar halaman tidak perlu mengimpor
/// router (dan menghindari import melingkar).
class AppPaths {
  AppPaths._();

  static const String home = '/home';
  static const String deliveryNew = '/delivery/new';
  static const String deliveryHistory = '/delivery/history';
  static const String deliveryPickLocation = '/delivery/pick-location';
  static const String wallet = '/wallet';

  static String deliveryDetail(String id) => '/delivery/$id';

  static String deliverySearching(String id) => '/delivery/$id/searching';

  static String deliveryPayment(String id) => '/delivery/$id/payment';
}
