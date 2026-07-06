import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/assets/apex_assets.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/snackbars.dart';
import '../../slots/domain/slot_models.dart';

/// BS-004 — Карта трассы (LOGIC-006, FL-12).
///
/// The map plugin is not agreed yet, so per the plan's fallback decision this
/// sheet renders the track geometry itself (when present), always shows the
/// meeting point text and opens an external map app for navigation.
Future<void> showTrackMapSheet(
  BuildContext context, {
  required String meetingPoint,
  num? meetingPointLat,
  num? meetingPointLng,
  List<List<num>>? geometry,
  TrackConfigType? trackType,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.7,
      child: TrackMapSheet(
        meetingPoint: meetingPoint,
        meetingPointLat: meetingPointLat,
        meetingPointLng: meetingPointLng,
        geometry: geometry,
        trackType: trackType,
      ),
    ),
  );
}

class TrackMapSheet extends StatelessWidget {
  const TrackMapSheet({
    required this.meetingPoint,
    this.meetingPointLat,
    this.meetingPointLng,
    this.geometry,
    this.trackType,
    super.key,
  });

  final String meetingPoint;
  final num? meetingPointLat;
  final num? meetingPointLng;
  final List<List<num>>? geometry;
  final TrackConfigType? trackType;

  bool get _hasCoordinates => meetingPointLat != null && meetingPointLng != null;

  bool get _hasGeometry => geometry != null && geometry!.length >= 2;

  String get _trackAsset => ApexAssets.trackMap(trackType!);

  Future<void> _openExternalMap(BuildContext context) async {
    final uri = Uri.parse(
      'https://yandex.ru/maps/?pt=$meetingPointLng,$meetingPointLat&z=16',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showAppSnack(context, 'Не удалось открыть внешнюю карту');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ApexSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Карта трассы',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: ApexSpacing.md),
          Expanded(
            child: trackType != null
                ? _TrackIllustration(assetPath: _trackAsset)
                : _hasGeometry
                    ? _TrackSchema(
                        geometry: geometry!,
                        meetingPointLat: meetingPointLat,
                        meetingPointLng: meetingPointLng,
                      )
                    : const _TextFallback(),
          ),
          const SizedBox(height: ApexSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: ApexColors.trackRed),
              const SizedBox(width: ApexSpacing.sm),
              Expanded(
                child: Text(
                  'Точка сбора: $meetingPoint',
                  style: textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: ApexSpacing.md),
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _hasCoordinates ? () => _openExternalMap(context) : null,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Открыть во внешней карте'),
              ),
            ),
          ),
          const SizedBox(height: ApexSpacing.sm),
        ],
      ),
    );
  }
}

class _TrackIllustration extends StatelessWidget {
  const _TrackIllustration({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ApexRadius.md),
      child: ColoredBox(
        color: ApexColors.trackMapBackdrop,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

class _TextFallback extends StatelessWidget {
  const _TextFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ApexColors.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(ApexRadius.md),
      ),
      padding: const EdgeInsets.all(ApexSpacing.lg),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_outlined, size: 48, color: ApexColors.muted),
          SizedBox(height: ApexSpacing.md),
          Text(
            'Схема трассы недоступна.\nОриентируйтесь на точку сбора ниже.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Draws the track polyline from API `geometry` in local coordinates.
class _TrackSchema extends StatelessWidget {
  const _TrackSchema({
    required this.geometry,
    this.meetingPointLat,
    this.meetingPointLng,
  });

  final List<List<num>> geometry;
  final num? meetingPointLat;
  final num? meetingPointLng;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ApexColors.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(ApexRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _TrackPainter(
          geometry: geometry,
          meetingPointLat: meetingPointLat,
          meetingPointLng: meetingPointLng,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({
    required this.geometry,
    this.meetingPointLat,
    this.meetingPointLng,
  });

  final List<List<num>> geometry;
  final num? meetingPointLat;
  final num? meetingPointLng;

  @override
  void paint(Canvas canvas, Size size) {
    final points = geometry
        .where((p) => p.length >= 2)
        .map((p) => (lat: p[0].toDouble(), lng: p[1].toDouble()))
        .toList();
    if (points.length < 2) {
      return;
    }

    var minLat = points.first.lat, maxLat = points.first.lat;
    var minLng = points.first.lng, maxLng = points.first.lng;
    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    final latSpan = (maxLat - minLat).abs().clamp(1e-9, double.infinity);
    final lngSpan = (maxLng - minLng).abs().clamp(1e-9, double.infinity);

    const inset = 32.0;
    Offset project(double lat, double lng) {
      final x = (lng - minLng) / lngSpan * (size.width - inset * 2) + inset;
      // Latitude grows north; canvas Y grows down.
      final y = (maxLat - lat) / latSpan * (size.height - inset * 2) + inset;
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final offset = project(points[i].lat, points[i].lng);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ApexColors.asphalt;
    canvas.drawPath(path, trackPaint);

    final startPaint = Paint()..color = ApexColors.grassGreen;
    canvas.drawCircle(project(points.first.lat, points.first.lng), 7, startPaint);

    if (meetingPointLat != null && meetingPointLng != null) {
      final pin = project(meetingPointLat!.toDouble(), meetingPointLng!.toDouble());
      final pinPaint = Paint()..color = ApexColors.trackRed;
      canvas.drawCircle(pin, 8, pinPaint);
      canvas.drawCircle(
        pin,
        12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ApexColors.trackRed,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) {
    return oldDelegate.geometry != geometry;
  }
}
