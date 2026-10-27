import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/coordinate.dart';
import '../../../domain/entities/jeneponto_service_area.dart';

/// Argumen untuk membuka pemilih titik peta.
class MapPickerArgs {
  const MapPickerArgs({required this.title, this.initialCoordinate});

  final String title;
  final Coordinate? initialCoordinate;
}

/// Hasil pemilihan titik peta.
class MapPickerResult {
  const MapPickerResult({
    required this.coordinate,
    required this.district,
  });

  final Coordinate coordinate;
  final String district;
}

/// Peta OpenStreetMap untuk memilih titik penjemputan/tujuan.
///
/// Titik hanya bisa dipakai bila berada di dalam batas Kabupaten Jeneponto.
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, this.args});

  final MapPickerArgs? args;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();

  LatLng? _selected;
  bool _insideArea = false;
  String? _district;

  @override
  void initState() {
    super.initState();
    final Coordinate? initial = widget.args?.initialCoordinate;
    if (initial != null && initial.isValid && !initial.isZero) {
      _selected = LatLng(initial.latitude, initial.longitude);
      _applySelection(_selected!, notify: false);
    }
  }

  void _applySelection(LatLng point, {bool notify = true}) {
    final Coordinate coordinate = Coordinate(point.latitude, point.longitude);
    final bool inside = JenepontoServiceArea.contains(coordinate);
    final JenepontoDistrict? detected =
        JenepontoServiceArea.districtAt(coordinate);
    final String district =
        detected?.name ?? JenepontoServiceArea.nearestDistrict(coordinate).name;
    void update() {
      _selected = point;
      _insideArea = inside;
      _district = district;
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  void _moveToDistrict(String? name) {
    final JenepontoDistrict? district =
        JenepontoServiceArea.districtByName(name);
    if (district == null) return;
    _mapController.move(
      LatLng(district.center.latitude, district.center.longitude),
      13,
    );
  }

  void _confirm() {
    final LatLng? point = _selected;
    if (point == null || !_insideArea) return;
    context.pop(
      MapPickerResult(
        coordinate: Coordinate(point.latitude, point.longitude),
        district: _district ?? '',
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Coordinate center = _selected == null
        ? JenepontoServiceArea.center
        : Coordinate(_selected!.latitude, _selected!.longitude);
    final bool canConfirm = _selected != null && _insideArea;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args?.title ?? 'Pilih Lokasi'),
        actions: [
          TextButton(
            onPressed: canConfirm ? _confirm : null,
            child: const Text('Pilih'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(center.latitude, center.longitude),
              initialZoom: 11.5,
              minZoom: 9,
              maxZoom: 18,
              onTap: (_, point) => _applySelection(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jeneponto.jeneponto_kurir',
                maxZoom: 19,
              ),
              PolygonLayer(
                polygons: <Polygon>[
                  for (final ring in JenepontoServiceArea.boundaryPolygons)
                    Polygon(
                      points: ring
                          .map((c) => LatLng(c.latitude, c.longitude))
                          .toList(growable: false),
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderColor: AppColors.primary,
                      borderStrokeWidth: 2.5,
                    ),
                  for (final district in JenepontoServiceArea.districts)
                    if (district.boundary.isNotEmpty)
                      Polygon(
                        points: district.boundary
                            .map((c) => LatLng(c.latitude, c.longitude))
                            .toList(growable: false),
                        color: Colors.transparent,
                        borderColor: AppColors.primary.withValues(alpha: 0.18),
                        borderStrokeWidth: 1,
                      ),
                ],
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: _selected!,
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.location_on,
                        size: 46,
                        color:
                            _insideArea ? AppColors.primary : AppColors.danger,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child:
                _MapHint(insideArea: _insideArea, hasPoint: _selected != null),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: _PickerSheet(
                selected: _selected,
                insideArea: _insideArea,
                district: _district,
                onDistrictChanged: _moveToDistrict,
                onConfirm: canConfirm ? _confirm : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.insideArea, required this.hasPoint});

  final bool insideArea;
  final bool hasPoint;

  @override
  Widget build(BuildContext context) {
    final bool ok = hasPoint && insideArea;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.info_outline,
            size: 18,
            color: ok ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              !hasPoint
                  ? 'Ketuk peta untuk memilih titik lokasi.'
                  : ok
                      ? 'Titik berada di area layanan Jeneponto.'
                      : 'Titik di luar area layanan. Pilih lokasi lain.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.selected,
    required this.insideArea,
    required this.district,
    required this.onDistrictChanged,
    required this.onConfirm,
  });

  final LatLng? selected;
  final bool insideArea;
  final String? district;
  final ValueChanged<String?> onDistrictChanged;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Titik lokasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '© OpenStreetMap',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            selected == null
                ? 'Belum ada titik dipilih'
                : '${selected!.latitude.toStringAsFixed(6)}, '
                    '${selected!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey<String?>(district),
            initialValue: district,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Lihat kecamatan',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            items: [
              for (final name in JenepontoServiceArea.districtNames)
                DropdownMenuItem<String>(value: name, child: Text(name)),
            ],
            onChanged: onDistrictChanged,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check, size: 18),
              label: Text(
                insideArea ? 'Gunakan Titik Ini' : 'Pilih Titik di Dalam Area',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
