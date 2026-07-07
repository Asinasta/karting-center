# BUG-001. В «Прошедших» бронь отображалась со статусом «Активна»

## Симптом

На SCR-005 «Мои записи» бронь с уже начавшимся заездом попадала в секцию «Прошедшие», но бейдж статуса показывал «Активна» вместо «Завершена».

## Требования

- `01-analysis/4-design/data-model.md` — статус `completed`: заезд состоялся.
- `01-analysis/5-mobile-app-spec/SCR-005-my-bookings.md` — группы «Предстоящие» / «Прошедшие».
- `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-010_Оценка-маршала.md` — после старта заезда допустимы `active` и `completed`.

## Причина

`groupBooking()` относил бронь к «Прошедшим» по времени (`now >= slot.startAt`), а `BookingStatusLabel` выводил сырой `status` из API без учёта начала заезда. Backend не переводил `active` → `completed` при чтении списка/детали брони.

## Исправление

- `backend/app/domain/policies.py` — `maybe_complete_booking_status()`.
- `backend/app/adapters/fixtures.py` — `_sync_booking_status()` при `list_bookings` / `get_booking`.
- `client/lib/features/booking/domain/booking_policies.dart` — `effectiveBookingStatus()`.
- `BookingStatusLabel` в `booking_list_screen.dart` и `booking_details_screen.dart` — статус через `effectiveBookingStatus`.

## Промпты

```
[скриншот]
Тут баг: в «Прошедших» бронь со статусом «Активна».
```

## Проверка вручную

1. Войти под seed-клиентом, открыть «Мои записи».
2. Убедиться, что заезды с прошедшим `start_at` в секции «Прошедшие» показывают «Завершена», не «Активна».
3. Предстоящие активные брони — в «Предстоящие» со статусом «Активна».

Автотесты:

- `backend/tests/test_bookings.py` — `test_list_bookings_completes_started_active_bookings`
- `client/test/domain/booking_policies_test.dart` — `effectiveBookingStatus`
