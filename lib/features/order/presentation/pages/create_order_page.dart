import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/price_calculator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';

/// Form pembuatan pesanan baru (kirim paket).
class CreateOrderPage extends StatelessWidget {
  const CreateOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderBloc>(
      create: (_) => sl<OrderBloc>(),
      child: const _CreateOrderView(),
    );
  }
}

class _CreateOrderView extends StatefulWidget {
  const _CreateOrderView();

  @override
  State<_CreateOrderView> createState() => _CreateOrderViewState();
}

class _CreateOrderViewState extends State<_CreateOrderView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _distanceController =
      TextEditingController(text: '1');

  double _distanceKm = 1;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  int get _price => PriceCalculator.estimate(distanceKm: _distanceKm);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;

    context.read<OrderBloc>().add(
          OrderCreateSubmitted(
            customerId: user.uid,
            customerName: user.name,
            pickupAddress: _pickupController.text.trim(),
            destinationAddress: _destinationController.text.trim(),
            distanceKm: _distanceKm,
            price: _price,
            note: _noteController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderBloc, OrderState>(
      listenWhen: (previous, current) =>
          (current.createdOrderId != null &&
              current.createdOrderId != previous.createdOrderId) ||
          (current.message != null && current.message != previous.message),
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.createdOrderId != null) {
          context.pop();
          messenger.showSnackBar(
            SnackBar(content: Text(state.message ?? 'Pesanan dibuat.')),
          );
        } else if (state.message != null) {
          messenger.showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Kirim Paket')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Alamat penjemputan',
                      controller: _pickupController,
                      hint: 'mis. Jl. Andi Mappasomba, Jeneponto',
                      maxLines: 2,
                      prefixIcon: Icons.trip_origin_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          Validators.required(value, field: 'Alamat penjemputan'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Alamat tujuan',
                      controller: _destinationController,
                      hint: 'mis. Pasar Binamu, Jeneponto',
                      maxLines: 2,
                      prefixIcon: Icons.location_on_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (value) =>
                          Validators.required(value, field: 'Alamat tujuan'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Jarak perkiraan (km)',
                      controller: _distanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefixIcon: Icons.route_outlined,
                      hint: 'mis. 4,5',
                      validator: Validators.distanceKm,
                      onChanged: (value) {
                        final parsed = double.tryParse(
                          value.replaceAll(',', '.').trim(),
                        );
                        setState(() => _distanceKm = parsed ?? 0);
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Catatan (opsional)',
                      controller: _noteController,
                      hint: 'mis. Barang pecah belah, hubungi dulu',
                      maxLines: 3,
                      prefixIcon: Icons.note_alt_outlined,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimasi tarif',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.rupiah(_price),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tarif dasar Rp 8.000 + Rp 2.500/km '
                            '(min. 1 km), dibulatkan per Rp500.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Buat Pesanan',
                      icon: Icons.local_shipping_outlined,
                      isLoading: state.isSubmitting,
                      onPressed: _submit,
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
