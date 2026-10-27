/// Path route khusus modul Person 2.
///
/// Host aplikasi dapat memakai konstanta ini untuk mendaftarkan route
/// pemesanan, pembayaran, dan dompet.
class AppPaths {
  AppPaths._();

  static const String deliveryNew = '/delivery/new';
  static const String deliveryHistory = '/delivery/history';
  static const String deliveryPickLocation = '/delivery/pick-location';
  static const String wallet = '/wallet';

  static String deliveryDetail(String id) => '/delivery/$id';

  static String deliverySearching(String id) => '/delivery/$id/searching';

  static String deliveryPayment(String id) => '/delivery/$id/payment';
}
