import 'slot_models.dart';

/// SlotFilterPolicy (LOGIC-005 / BS-001).
///
/// Groups: date period, track type, marshal, only available.
/// OR inside a multi-value group, AND between groups — enforced server-side;
/// the client only builds the query. Default period: next 7 days.
class SlotFilter {
  const SlotFilter({
    this.dateFrom,
    this.dateTo,
    this.trackConfigTypes = const {},
    this.marshalIds = const {},
    this.onlyAvailable = false,
  });

  /// Default filter: no explicit values; the backend applies the
  /// "next 7 days" period itself when no dates are sent.
  static const SlotFilter defaults = SlotFilter();

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final Set<TrackConfigType> trackConfigTypes;
  final Set<String> marshalIds;
  final bool onlyAvailable;

  bool get isDefault =>
      dateFrom == null &&
      dateTo == null &&
      trackConfigTypes.isEmpty &&
      marshalIds.isEmpty &&
      !onlyAvailable;

  int get activeGroupCount {
    var count = 0;
    if (dateFrom != null || dateTo != null) count++;
    if (trackConfigTypes.isNotEmpty) count++;
    if (marshalIds.isNotEmpty) count++;
    if (onlyAvailable) count++;
    return count;
  }

  SlotFilter copyWith({
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
    Set<TrackConfigType>? trackConfigTypes,
    Set<String>? marshalIds,
    bool? onlyAvailable,
  }) {
    return SlotFilter(
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      trackConfigTypes: trackConfigTypes ?? this.trackConfigTypes,
      marshalIds: marshalIds ?? this.marshalIds,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    );
  }

  /// Query parameters for `GET /slots` (LOGIC-005 parameter names).
  Map<String, Object> toQuery() {
    return {
      if (dateFrom != null) 'date_from': dateFrom!.toUtc().toIso8601String(),
      if (dateTo != null) 'date_to': dateTo!.toUtc().toIso8601String(),
      if (trackConfigTypes.isNotEmpty)
        'track_config_type':
            trackConfigTypes.map((t) => t.apiValue).toList(growable: false),
      if (marshalIds.isNotEmpty) 'marshal_id': marshalIds.toList(growable: false),
      if (onlyAvailable) 'only_available': 'true',
    };
  }
}
