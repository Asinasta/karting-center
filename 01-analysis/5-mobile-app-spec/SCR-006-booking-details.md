# SCR-006 — Детали брони

## API

- `getBooking`: `GET /bookings/{bookingId}`
- `cancelBooking`: `POST /bookings/{bookingId}/cancel`
- `rateMarshal` / `updateMarshalRating` / `deleteMarshalRating`: `POST` / `PATCH` / `DELETE /bookings/{bookingId}/marshal-rating`

## UI

Параметры брони из snapshot слота, статус, причина отмены центром, карта, кнопка отмены для активной предстоящей брони.

Блок оценки маршала (1–5 звёзд, опциональный комментарий) после старта заезда — см. LOGIC-010.

Если `Booking.status = cancelled_by_center` или `Booking.slot.status = cancelled`, детали показывают актуальную причину отмены центром и отключают повторную запись на этот слот.

## Применяемые логики

LOGIC-004, LOGIC-006, LOGIC-008, LOGIC-010.
