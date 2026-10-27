import 'package:equatable/equatable.dart';

import 'coordinate.dart';
import 'jeneponto_service_area.dart';

/// Alamat lengkap untuk penjemputan atau tujuan pengiriman.
///
/// Menyimpan teks alamat, kecamatan, kontak, dan titik peta. Titik peta
/// wajib untuk pesanan baru agar tarif dan area layanan bisa divalidasi.
class DeliveryAddress extends Equatable {
  const DeliveryAddress({
    required this.label,
    required this.address,
    required this.district,
    required this.coordinate,
    required this.contactName,
    required this.contactPhone,
    this.notes = '',
  });

  /// Label singkat, mis. "Rumah", "Kantor", "Pasar".
  final String label;

  /// Detail alamat (jalan, nomor, patokan).
  final String address;

  /// Nama kecamatan di Kabupaten Jeneponto.
  final String district;

  final Coordinate coordinate;
  final String contactName;
  final String contactPhone;
  final String notes;

  bool get hasPoint => coordinate.isValid && !coordinate.isZero;

  bool get isWithinServiceArea =>
      hasPoint && JenepontoServiceArea.contains(coordinate);

  /// Alamat satu baris untuk ditampilkan di kartu pesanan.
  String get fullAddress {
    final String detail = address.trim();
    final String area = district.trim();
    if (detail.isEmpty) return area;
    if (area.isEmpty) return detail;
    if (detail.toLowerCase().contains(area.toLowerCase())) return detail;
    return '$detail, Kec. $area';
  }

  DeliveryAddress copyWith({
    String? label,
    String? address,
    String? district,
    Coordinate? coordinate,
    String? contactName,
    String? contactPhone,
    String? notes,
  }) {
    return DeliveryAddress(
      label: label ?? this.label,
      address: address ?? this.address,
      district: district ?? this.district,
      coordinate: coordinate ?? this.coordinate,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        label,
        address,
        district,
        coordinate,
        contactName,
        contactPhone,
        notes,
      ];
}
