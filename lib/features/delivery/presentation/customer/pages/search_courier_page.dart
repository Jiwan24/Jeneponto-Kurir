import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/di/injector.dart';
import '../../../../../core/router/app_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/price_calculator.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../domain/entities/coordinate.dart';
import '../../../domain/entities/delivery_address.dart';
import '../../../domain/entities/delivery_order.dart';
import '../../../domain/entities/jeneponto_service_area.dart';
import '../../../domain/entities/payment_method.dart';
import '../../bloc/delivery_checkout_bloc.dart';
import '../../bloc/delivery_checkout_state.dart';
import 'map_picker_page.dart';

/// Halaman utama "Cari Kurir": form alamat, titik peta, tarif, dan bayar.
class SearchCourierPage extends StatelessWidget {
  const SearchCourierPage({super.key, this.embedded = false});

  /// True bila dipakai sebagai tab di [HomeShell] (tanpa tombol back).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final UserEntity? user = context.watch<AuthBloc>().state.user;
    return BlocProvider<DeliveryCheckoutBloc>(
      create: (_) => sl<DeliveryCheckoutBloc>(),
      child: _SearchCourierView(user: user, embedded: embedded),
    );
  }
}

class _SearchCourierView extends StatefulWidget {
  const _SearchCourierView({required this.user, required this.embedded});

  final UserEntity? user;
  final bool embedded;

  @override
  State<_SearchCourierView> createState() => _SearchCourierViewState();
}

class _SearchCourierViewState extends State<_SearchCourierView> {
  static const List<String> _categories = <String>[
    'Paket',
    'Dokumen',
    'Makanan',
    'Elektronik',
    'Lainnya',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _pickupName;
  late final TextEditingController _pickupPhone;
  final TextEditingController _pickupAddress = TextEditingController();
  late final TextEditingController _dropoffName;
  late final TextEditingController _dropoffPhone;
  final TextEditingController _dropoffAddress = TextEditingController();
  final TextEditingController _weight = TextEditingController(text: '1');
  final TextEditingController _notes = TextEditingController();

  String? _pickupDistrict;
  String? _dropoffDistrict;
  Coordinate? _pickupPoint;
  Coordinate? _dropoffPoint;
  String _category = _categories.first;
  PaymentMethod _paymentMethod = PaymentMethod.cod;

  @override
  void initState() {
    super.initState();
    _pickupName = TextEditingController(text: widget.user?.name ?? '');
    _pickupPhone = TextEditingController(text: widget.user?.phone ?? '');
    _dropoffName = TextEditingController();
    _dropoffPhone = TextEditingController();
  }

  @override
  void dispose() {
    _pickupName.dispose();
    _pickupPhone.dispose();
    _pickupAddress.dispose();
    _dropoffName.dispose();
    _dropoffPhone.dispose();
    _dropoffAddress.dispose();
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? get _rawDistance {
    final Coordinate? from = _pickupPoint;
    final Coordinate? to = _dropoffPoint;
    if (from == null || to == null) return null;
    return from.distanceToKm(to) * AppConstants.roadDistanceFactor;
  }

  double? get _distanceKm {
    final double? raw = _rawDistance;
    if (raw == null) return null;
    return raw.clamp(0.5, AppConstants.maximumDeliveryDistanceKm);
  }

  bool get _distanceTooFar =>
      (_rawDistance ?? 0) > AppConstants.maximumDeliveryDistanceKm;

  FareBreakdown? get _fare {
    final double? distance = _distanceKm;
    if (distance == null || _distanceTooFar) return null;
    return PriceCalculator.quote(distanceKm: distance);
  }

  Future<void> _pickPoint({required bool pickup}) async {
    final Coordinate? initial = pickup ? _pickupPoint : _dropoffPoint;
    final MapPickerResult? result = await context.push<MapPickerResult>(
      AppPaths.deliveryPickLocation,
      extra: MapPickerArgs(
        title: pickup ? 'Titik Penjemputan' : 'Titik Tujuan',
        initialCoordinate: initial,
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (pickup) {
        _pickupPoint = result.coordinate;
        _pickupDistrict = result.district;
      } else {
        _dropoffPoint = result.coordinate;
        _dropoffDistrict = result.district;
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_pickupPoint == null || _dropoffPoint == null) {
      _showMessage('Pilih titik penjemputan dan tujuan di peta.');
      return;
    }
    if (!JenepontoServiceArea.contains(_pickupPoint!)) {
      _showMessage(
        'Titik penjemputan berada di luar area layanan Jeneponto.',
      );
      return;
    }
    if (!JenepontoServiceArea.contains(_dropoffPoint!)) {
      _showMessage('Titik tujuan berada di luar area layanan Jeneponto.');
      return;
    }
    if (_distanceTooFar) {
      _showMessage(
        'Jarak terlalu jauh (maks. '
        '${AppConstants.maximumDeliveryDistanceKm.toInt()} km).',
      );
      return;
    }

    final UserEntity? user = widget.user;
    if (user == null) {
      _showMessage('Sesi login tidak ditemukan. Silakan masuk ulang.');
      return;
    }

    final DeliveryAddress pickup = DeliveryAddress(
      label: 'Penjemputan',
      address: _pickupAddress.text.trim(),
      district: _pickupDistrict ?? '',
      coordinate: _pickupPoint!,
      contactName: _pickupName.text.trim(),
      contactPhone: _pickupPhone.text.trim(),
    );
    final DeliveryAddress dropoff = DeliveryAddress(
      label: 'Tujuan',
      address: _dropoffAddress.text.trim(),
      district: _dropoffDistrict ?? '',
      coordinate: _dropoffPoint!,
      contactName: _dropoffName.text.trim(),
      contactPhone: _dropoffPhone.text.trim(),
    );

    context.read<DeliveryCheckoutBloc>().add(
          DeliveryCheckoutSubmitted(
            DeliveryDraft(
              customerId: user.uid,
              customerName: user.name,
              customerPhone: user.phone,
              pickup: pickup,
              dropoff: dropoff,
              distanceKm: _distanceKm!,
              paymentMethod: _paymentMethod,
              itemCategory: _category,
              weightKg: double.tryParse(_weight.text.replaceAll(',', '.')) ?? 1,
              itemNotes: _notes.text.trim(),
            ),
          ),
        );
  }

  void _onCheckoutSuccess(DeliveryCheckoutState state) {
    final String? id = state.createdOrderId;
    if (id == null) return;
    final String target = state.paymentMethod == PaymentMethod.midtrans
        ? AppPaths.deliveryPayment(id)
        : AppPaths.deliverySearching(id);
    // Saat form menjadi tab HomeShell, `pushReplacement` akan mengganti
    // seluruh shell. Gunakan push agar tombol kembali tetap ke beranda.
    if (widget.embedded) {
      context.push(target);
    } else {
      context.pushReplacement(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryCheckoutBloc, DeliveryCheckoutState>(
      listenWhen: (previous, current) =>
          current.status != previous.status ||
          current.createdOrderId != previous.createdOrderId ||
          current.message != previous.message,
      listener: (context, state) {
        if (state.createdOrderId != null &&
            state.status == DeliveryCheckoutStatus.success) {
          _onCheckoutSuccess(state);
        } else if (state.status == DeliveryCheckoutStatus.failure &&
            state.message != null) {
          _showMessage(state.message!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cari Kurir'),
            automaticallyImplyLeading: !widget.embedded,
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HeroCard(),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Alamat Penjemputan',
                      subtitle: 'Dari mana paket diambil?',
                      icon: Icons.trip_origin,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _FormCard(
                      children: [
                        AppTextField(
                          label: 'Nama pengirim',
                          controller: _pickupName,
                          hint: 'Nama lengkap',
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: (value) => Validators.personName(
                            value,
                            field: 'Nama pengirim',
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Nomor HP pengirim',
                          controller: _pickupPhone,
                          hint: '0812xxxxxxx',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          textInputAction: TextInputAction.next,
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Detail alamat',
                          controller: _pickupAddress,
                          hint: 'Jl. ..., nomor rumah, patokan',
                          maxLines: 2,
                          prefixIcon: Icons.home_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (value) => Validators.addressDetail(
                            value,
                            field: 'Alamat penjemputan',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DistrictField(
                          value: _pickupDistrict,
                          onChanged: (value) =>
                              setState(() => _pickupDistrict = value),
                        ),
                        const SizedBox(height: 12),
                        _PointTile(
                          title: 'Titik penjemputan',
                          point: _pickupPoint,
                          onTap: () => _pickPoint(pickup: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Alamat Tujuan',
                      subtitle: 'Siapa yang menerima paket?',
                      icon: Icons.location_on,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 10),
                    _FormCard(
                      children: [
                        AppTextField(
                          label: 'Nama penerima',
                          controller: _dropoffName,
                          hint: 'Nama lengkap penerima',
                          prefixIcon: Icons.person_outline,
                          textInputAction: TextInputAction.next,
                          validator: (value) => Validators.personName(
                            value,
                            field: 'Nama penerima',
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Nomor HP penerima',
                          controller: _dropoffPhone,
                          hint: '0812xxxxxxx',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          textInputAction: TextInputAction.next,
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Detail alamat tujuan',
                          controller: _dropoffAddress,
                          hint: 'Jl. ..., nomor rumah, patokan',
                          maxLines: 2,
                          prefixIcon: Icons.home_outlined,
                          textInputAction: TextInputAction.next,
                          validator: (value) => Validators.addressDetail(
                            value,
                            field: 'Alamat tujuan',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DistrictField(
                          value: _dropoffDistrict,
                          onChanged: (value) =>
                              setState(() => _dropoffDistrict = value),
                        ),
                        const SizedBox(height: 12),
                        _PointTile(
                          title: 'Titik tujuan',
                          point: _dropoffPoint,
                          onTap: () => _pickPoint(pickup: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Detail Paket',
                      subtitle: 'Bantu kurir menyiapkan kendaraan.',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _FormCard(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Kategori paket',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: [
                            for (final category in _categories)
                              DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Berat paket (kg)',
                          controller: _weight,
                          hint: 'mis. 1,5',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefixIcon: Icons.scale_outlined,
                          textInputAction: TextInputAction.next,
                          validator: Validators.weightKg,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Catatan untuk kurir (opsional)',
                          controller: _notes,
                          hint: 'mis. Barang pecah belah, hubungi dulu',
                          maxLines: 3,
                          prefixIcon: Icons.note_alt_outlined,
                          textInputAction: TextInputAction.done,
                          validator: Validators.itemNotes,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Metode Pembayaran',
                      subtitle: 'Pilih cara membayar pengiriman.',
                      icon: Icons.payments_outlined,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 10),
                    _PaymentMethodSelector(
                      value: _paymentMethod,
                      onChanged: (value) =>
                          setState(() => _paymentMethod = value),
                    ),
                    const SizedBox(height: 16),
                    _FareEstimateCard(
                      fare: _fare,
                      distanceTooFar: _distanceTooFar,
                      hasBothPoints:
                          _pickupPoint != null && _dropoffPoint != null,
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Cari Kurir',
                      icon: Icons.search,
                      isLoading: state.isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Dengan memesan, kamu menyetujui tarif estimasi. '
                      'Tarif final dihitung ulang oleh sistem.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kirim paket di Jeneponto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tentukan titik jemput & tujuan, lalu cari kurir terdekat.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _DistrictField extends StatelessWidget {
  const _DistrictField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(value),
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Kecamatan',
        prefixIcon: Icon(Icons.map_outlined),
      ),
      hint: const Text('Pilih kecamatan'),
      items: [
        for (final name in JenepontoServiceArea.districtNames)
          DropdownMenuItem<String>(value: name, child: Text(name)),
      ],
      onChanged: onChanged,
      validator: Validators.district,
    );
  }
}

class _PointTile extends StatelessWidget {
  const _PointTile({
    required this.title,
    required this.point,
    required this.onTap,
  });

  final String title;
  final Coordinate? point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool selected = point != null;
    final bool inside = selected && JenepontoServiceArea.contains(point!);
    final JenepontoDistrict? district =
        selected ? JenepontoServiceArea.districtAt(point!) : null;
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? (inside ? AppColors.primary : AppColors.danger)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.pin_drop_outlined,
                color: selected
                    ? (inside ? AppColors.primary : AppColors.danger)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      selected
                          ? '${district?.name ?? JenepontoServiceArea.nearestDistrict(point!).name}'
                              ' • ${point!.latitude.toStringAsFixed(5)}, '
                              '${point!.longitude.toStringAsFixed(5)}'
                          : 'Ketuk untuk memilih di peta',
                      style: TextStyle(
                        fontSize: 11,
                        color: selected && !inside
                            ? AppColors.danger
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.value,
    required this.onChanged,
  });

  final PaymentMethod value;
  final ValueChanged<PaymentMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final method in PaymentMethod.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PaymentOption(
              method: method,
              selected: value == method,
              onTap: () => onChanged(method),
            ),
          ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.06)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                method == PaymentMethod.cod
                    ? Icons.payments_outlined
                    : Icons.qr_code_2,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      method.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FareEstimateCard extends StatelessWidget {
  const _FareEstimateCard({
    required this.fare,
    required this.distanceTooFar,
    required this.hasBothPoints,
  });

  final FareBreakdown? fare;
  final bool distanceTooFar;
  final bool hasBothPoints;

  @override
  Widget build(BuildContext context) {
    if (fare == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          distanceTooFar
              ? 'Jarak melebihi batas layanan. Pilih titik yang lebih dekat.'
              : hasBothPoints
                  ? 'Jarak terlalu dekat. Minimal 0,5 km.'
                  : 'Pilih titik jemput dan tujuan untuk melihat estimasi tarif.',
          style: TextStyle(
            fontSize: 12,
            color: distanceTooFar ? AppColors.danger : AppColors.textSecondary,
          ),
        ),
      );
    }

    final FareBreakdown value = fare!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.route_outlined, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Estimasi Tarif',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('Tarif dasar', Formatters.rupiah(value.baseFare)),
          const SizedBox(height: 4),
          _row(
            'Jarak ${Formatters.distance(value.distanceKm)}',
            Formatters.rupiah(value.distanceCharge),
          ),
          if (value.roundingAdjustment != 0) ...[
            const SizedBox(height: 4),
            _row('Pembulatan', Formatters.rupiah(value.roundingAdjustment)),
          ],
          const Divider(height: 20),
          Row(
            children: [
              const Text(
                'Total estimasi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.rupiah(value.total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Jarak mengikuti titik peta + faktor jalan. '
            'Tarif final divalidasi sistem.',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
