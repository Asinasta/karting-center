import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/load_state.dart';
import '../../../core/ui/screen_states.dart';
import '../domain/slot_filter.dart';
import '../domain/slot_models.dart';
import 'filters_sheet.dart';
import 'slot_card.dart';

/// SCR-002 — Список заездов (FL-04). Public, no token.
class SlotListScreen extends StatefulWidget {
  const SlotListScreen({super.key});

  @override
  State<SlotListScreen> createState() => _SlotListScreenState();
}

class _SlotListScreenState extends State<SlotListScreen> {
  LoadState<List<Slot>> _state = const Loading();
  SlotFilter _filter = SlotFilter.defaults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load({bool refreshing = false}) async {
    final deps = AppScope.of(context);
    final previous = _state;
    if (!refreshing) {
      setState(() => _state = const Loading());
    } else if (previous case Content<List<Slot>>(data: final data)) {
      setState(() => _state = Content(data, refreshing: true));
    }

    try {
      final slots = await deps.slotRepository.listSlots(filter: _filter);
      if (!mounted) return;
      deps.slotsCache.store(slots);
      setState(() {
        _state = slots.isEmpty ? const Empty() : Content(slots);
      });
    } on Object catch (error) {
      if (!mounted) return;
      final failure = toAppFailure(error);
      // Network failure -> read-only fallback from cache (Offline stale).
      final cached = deps.slotsCache.value;
      setState(() {
        if (failure.isNetwork && cached != null && cached.isNotEmpty) {
          _state = OfflineStale(cached);
        } else {
          _state = Failure(failure);
        }
      });
    }
  }

  Future<void> _openFilters() async {
    final updated = await showFiltersSheet(context, _filter);
    if (updated == null || !mounted) {
      return;
    }
    setState(() => _filter = updated);
    await _load();
  }

  void _openSlot(Slot slot) {
    context.go('/slots/${slot.id}');
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = _filter.activeGroupCount;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Фильтры',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: filterCount > 0,
              label: Text('$filterCount'),
              child: Icon(
                filterCount > 0 ? Icons.filter_alt : Icons.filter_alt_outlined,
              ),
            ),
          ),
        ],
      ),
      body: _body(),
      bottomNavigationBar: const ApexBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _body() {
    return switch (_state) {
      Loading<List<Slot>>() => const LoadingStateView(),
      Empty<List<Slot>>() => _EmptyWithFilters(
          isFiltered: !_filter.isDefault,
          onResetFilters: () {
            setState(() => _filter = SlotFilter.defaults);
            _load();
          },
          onRetry: () => _load(),
        ),
      Failure<List<Slot>>(error: final error) => ErrorStateView(
          message: error.uiMessage,
          onRetry: () => _load(),
        ),
      OfflineStale<List<Slot>>(data: final slots) => Column(
          children: [
            const OfflineStaleBanner(),
            Expanded(child: _slotList(slots, refreshing: false)),
          ],
        ),
      Content<List<Slot>>(data: final slots, refreshing: final refreshing) =>
        _slotList(slots, refreshing: refreshing),
    };
  }

  Widget _slotList(List<Slot> slots, {required bool refreshing}) {
    return RefreshIndicator(
      onRefresh: () => _load(refreshing: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(ApexSpacing.md),
        itemCount: slots.length + (refreshing ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: ApexSpacing.md),
        itemBuilder: (context, index) {
          if (refreshing && index == 0) {
            return const LinearProgressIndicator();
          }
          final slot = slots[refreshing ? index - 1 : index];
          return SlotCard(
            slot: slot,
            onTap: () => _openSlot(slot),
            onBook: slot.isAvailable ? () => _openSlot(slot) : null,
          );
        },
      ),
    );
  }
}

class _EmptyWithFilters extends StatelessWidget {
  const _EmptyWithFilters({
    required this.isFiltered,
    required this.onResetFilters,
    required this.onRetry,
  });

  final bool isFiltered;
  final VoidCallback onResetFilters;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ApexSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 40),
            const SizedBox(height: ApexSpacing.md),
            Text(
              isFiltered
                  ? 'По выбранным фильтрам заездов не нашлось'
                  : 'Пока нет доступных заездов',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: ApexSpacing.md),
            if (isFiltered)
              FilledButton(
                onPressed: onResetFilters,
                child: const Text('Сбросить фильтры'),
              )
            else
              FilledButton(
                onPressed: onRetry,
                child: const Text('Обновить'),
              ),
          ],
        ),
      ),
    );
  }
}
