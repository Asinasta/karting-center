import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/formats.dart';
import '../domain/period_preset.dart';
import '../domain/slot_filter.dart';
import '../domain/slot_models.dart';

/// BS-001 — Фильтры (LOGIC-005).
///
/// Returns the new [SlotFilter] via Navigator.pop, or null when dismissed.
Future<SlotFilter?> showFiltersSheet(BuildContext context, SlotFilter current) {
  return showModalBottomSheet<SlotFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: ApexColors.surface,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _FiltersSheet(initial: current),
    ),
  );
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial});

  final SlotFilter initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late PeriodPreset _preset = detectPreset(
    widget.initial.dateFrom,
    widget.initial.dateTo,
    DateTime.now(),
  );
  late DateTime? _customFrom = widget.initial.dateFrom;
  late DateTime? _customTo = widget.initial.dateTo;
  late Set<TrackConfigType> _types = {...widget.initial.trackConfigTypes};
  late Set<String> _marshalIds = {...widget.initial.marshalIds};
  late bool _onlyAvailable = widget.initial.onlyAvailable;

  List<Marshal>? _marshals;
  String? _marshalsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarshals());
  }

  Future<void> _loadMarshals() async {
    setState(() => _marshalsError = null);
    try {
      final marshals = await AppScope.of(context).marshalRepository.listMarshals();
      if (!mounted) return;
      setState(() => _marshals = marshals);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _marshalsError = toAppFailure(error).uiMessage);
    }
  }

  void _selectPreset(PeriodPreset preset) {
    setState(() {
      _preset = preset;
      if (preset != PeriodPreset.custom) {
        _customFrom = null;
        _customTo = null;
      }
    });
    if (preset == PeriodPreset.custom) {
      _pickCustomRange();
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDateRange: _customFrom != null && _customTo != null
          ? DateTimeRange(start: _customFrom!, end: _customTo!)
          : DateTimeRange(start: today, end: today.add(const Duration(days: 7))),
      helpText: 'Период заездов',
      confirmText: 'Выбрать',
      cancelText: 'Отмена',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              headerHeadlineStyle: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          child: child!,
        );
      },
    );
    if (range == null || !mounted) {
      if (_customFrom == null && _customTo == null) {
        setState(() => _preset = PeriodPreset.next7Days);
      }
      return;
    }
    setState(() {
      _preset = PeriodPreset.custom;
      _customFrom = DateTime(range.start.year, range.start.month, range.start.day);
      _customTo = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
    });
  }

  void _reset() {
    setState(() {
      _preset = PeriodPreset.next7Days;
      _customFrom = null;
      _customTo = null;
      _types = {};
      _marshalIds = {};
      _onlyAvailable = false;
    });
  }

  void _apply() {
    final dates = presetToFilterDates(
      preset: _preset,
      customFrom: _customFrom,
      customTo: _customTo,
      now: DateTime.now(),
    );
    Navigator.of(context).pop(
      SlotFilter(
        dateFrom: dates.dateFrom,
        dateTo: dates.dateTo,
        trackConfigTypes: _types,
        marshalIds: _marshalIds,
        onlyAvailable: _onlyAvailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ApexSpacing.lg),
          child: Row(
            children: [
              Text(
                'Фильтры',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: _reset,
                child: const Text('Сбросить'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: ApexSpacing.lg),
            children: [
              const _SectionTitle('Период'),
              Wrap(
                spacing: ApexSpacing.sm,
                runSpacing: ApexSpacing.xs,
                children: PeriodPreset.values.map((preset) {
                  final selected = _preset == preset;
                  return FilterChip(
                    label: Text(preset.label),
                    selected: selected,
                    onSelected: (value) {
                      if (value) _selectPreset(preset);
                    },
                  );
                }).toList(),
              ),
              if (_preset == PeriodPreset.custom &&
                  _customFrom != null &&
                  _customTo != null) ...[
                const SizedBox(height: ApexSpacing.xs),
                Text(
                  '${formatShortDate(_customFrom!)} — ${formatShortDate(_customTo!)}',
                  style: textTheme.bodySmall?.copyWith(color: ApexColors.muted),
                ),
              ],
              const SizedBox(height: ApexSpacing.md),
              const _SectionTitle('Тип трассы'),
              Wrap(
                spacing: ApexSpacing.sm,
                children: TrackConfigType.values.map((type) {
                  final selected = _types.contains(type);
                  return FilterChip(
                    label: Text(type.label),
                    selected: selected,
                    onSelected: (value) => setState(() {
                      if (value) {
                        _types.add(type);
                      } else {
                        _types.remove(type);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: ApexSpacing.md),
              const _SectionTitle('Маршал'),
              if (_marshals == null && _marshalsError == null)
                const Padding(
                  padding: EdgeInsets.all(ApexSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_marshalsError != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _marshalsError!,
                        style: const TextStyle(color: ApexColors.trackRed),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadMarshals,
                      child: const Text('Повторить'),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: ApexSpacing.sm,
                  runSpacing: ApexSpacing.xs,
                  children: _marshals!.map((marshal) {
                    final selected = _marshalIds.contains(marshal.id);
                    return FilterChip(
                      label: Text(marshal.name),
                      selected: selected,
                      onSelected: (value) => setState(() {
                        if (value) {
                          _marshalIds.add(marshal.id);
                        } else {
                          _marshalIds.remove(marshal.id);
                        }
                      }),
                    );
                  }).toList(),
                ),
              const SizedBox(height: ApexSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Только свободные'),
                value: _onlyAvailable,
                onChanged: (value) => setState(() => _onlyAvailable = value),
              ),
              const SizedBox(height: ApexSpacing.xl),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(ApexSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _apply,
                child: const Text('Применить'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ApexSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
