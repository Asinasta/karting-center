import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../app/app_scope.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/apex_tokens.dart';
import '../../../core/ui/formats.dart';
import '../../../core/ui/load_state.dart';
import '../../../core/ui/screen_states.dart';
import '../domain/booking_models.dart';
import '../domain/booking_policies.dart';

const _pageSize = 20;

/// SCR-005 — Мои записи (FL-09). Protected by the router auth gate.
class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  LoadState<List<Booking>> _state = const Loading();
  int _total = 0;
  bool _loadingMore = false;

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
    } else if (previous case Content<List<Booking>>(data: final data)) {
      setState(() => _state = Content(data, refreshing: true));
    }

    try {
      final page =
          await deps.bookingRepository.listBookings(limit: _pageSize, offset: 0);
      if (!mounted) return;
      deps.bookingsCache.store(page.items);
      setState(() {
        _total = page.pagination?.total ?? page.items.length;
        _state = page.items.isEmpty ? const Empty() : Content(page.items);
      });
    } on Object catch (error) {
      if (!mounted) return;
      final failure = toAppFailure(error);
      final cached = deps.bookingsCache.value;
      setState(() {
        if (failure.isNetwork && cached != null && cached.isNotEmpty) {
          _state = OfflineStale(cached);
        } else {
          _state = Failure(failure);
        }
      });
    }
  }

  Future<void> _loadMore() async {
    final current = _state;
    if (_loadingMore || current is! Content<List<Booking>>) {
      return;
    }
    final loaded = current.data;
    if (loaded.length >= _total) {
      return;
    }

    setState(() => _loadingMore = true);
    final deps = AppScope.of(context);
    try {
      final page = await deps.bookingRepository
          .listBookings(limit: _pageSize, offset: loaded.length);
      if (!mounted) return;
      final merged = [...loaded, ...page.items];
      deps.bookingsCache.store(merged);
      setState(() {
        _total = page.pagination?.total ?? merged.length;
        _state = Content(merged);
        _loadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(toAppFailure(error).uiMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Мои записи'),
      ),
      body: _body(),
      bottomNavigationBar: const ApexBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _body() {
    return switch (_state) {
      Loading<List<Booking>>() => const LoadingStateView(),
      Empty<List<Booking>>() => Center(
          child: Padding(
            padding: const EdgeInsets.all(ApexSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_note_outlined, size: 40),
                const SizedBox(height: ApexSpacing.md),
                const Text('У вас пока нет записей на заезды'),
                const SizedBox(height: ApexSpacing.md),
                FilledButton(
                  onPressed: () => context.go('/slots'),
                  child: const Text('Выбрать заезд'),
                ),
              ],
            ),
          ),
        ),
      Failure<List<Booking>>(error: final error) => ErrorStateView(
          message: error.uiMessage,
          onRetry: () => _load(),
        ),
      OfflineStale<List<Booking>>(data: final bookings) => Column(
          children: [
            const OfflineStaleBanner(),
            Expanded(child: _groupedList(bookings, refreshing: false)),
          ],
        ),
      Content<List<Booking>>(data: final bookings, refreshing: final refreshing) =>
        _groupedList(bookings, refreshing: refreshing),
    };
  }

  Widget _groupedList(List<Booking> bookings, {required bool refreshing}) {
    final now = DateTime.now();
    final upcoming = <Booking>[];
    final past = <Booking>[];
    final cancelled = <Booking>[];
    for (final booking in bookings) {
      switch (groupBooking(booking, now)) {
        case BookingGroup.upcoming:
          upcoming.add(booking);
        case BookingGroup.past:
          past.add(booking);
        case BookingGroup.cancelled:
          cancelled.add(booking);
      }
    }
    upcoming.sort((a, b) => a.slot.startAt.compareTo(b.slot.startAt));
    past.sort((a, b) => b.slot.startAt.compareTo(a.slot.startAt));
    cancelled.sort((a, b) => b.slot.startAt.compareTo(a.slot.startAt));

    final children = <Widget>[
      if (refreshing) const LinearProgressIndicator(),
      ..._section('Предстоящие', upcoming),
      ..._section('Прошедшие', past),
      ..._section('Отменённые', cancelled),
      if (bookings.length < _total)
        Padding(
          padding: const EdgeInsets.all(ApexSpacing.md),
          child: Center(
            child: _loadingMore
                ? const CircularProgressIndicator()
                : OutlinedButton(
                    onPressed: _loadMore,
                    child: const Text('Показать ещё'),
                  ),
          ),
        ),
    ];

    return RefreshIndicator(
      onRefresh: () => _load(refreshing: true),
      child: ListView(
        padding: const EdgeInsets.all(ApexSpacing.md),
        children: children,
      ),
    );
  }

  List<Widget> _section(String title, List<Booking> bookings) {
    if (bookings.isEmpty) {
      return const [];
    }
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: ApexSpacing.sm),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      for (final booking in bookings) ...[
        _BookingCard(
          booking: booking,
          onTap: () => context.go('/bookings/${booking.id}'),
        ),
        const SizedBox(height: ApexSpacing.sm),
      ],
      const SizedBox(height: ApexSpacing.sm),
    ];
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
  });

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final slot = booking.slot;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ApexRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(ApexSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      slot.trackConfig.name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  BookingStatusLabel(status: booking.status),
                ],
              ),
              const SizedBox(height: ApexSpacing.xs),
              Text(formatDateTimeWithWeekday(slot.startAt)),
              const SizedBox(height: ApexSpacing.xs),
              Text(
                'Мест: ${booking.seatsCount} · ${booking.priceTotal.formatted}',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingStatusLabel extends StatelessWidget {
  const BookingStatusLabel({
    required this.status,
    super.key,
  });

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.active => ApexColors.grassGreen,
      BookingStatus.completed => ApexColors.muted,
      BookingStatus.cancelled ||
      BookingStatus.lateCancel ||
      BookingStatus.cancelledByCenter =>
        ApexColors.trackRed,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(ApexRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ApexSpacing.sm,
          vertical: ApexSpacing.xs,
        ),
        child: Text(
          status.label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
