# SCR-006 — Детали брони

## API

- `getBooking`: `GET /bookings/{bookingId}`
- `cancelBooking`: `POST /bookings/{bookingId}/cancel`

## UI

Параметры брони из snapshot слота, статус, причина отмены центром, карта, кнопка отмены для активной предстоящей брони.

Если `Booking.status = cancelled_by_center` или `Booking.slot.status = cancelled`, детали показывают актуальную причину отмены центром и отключают повторную запись на этот слот.

## Применяемые логики

LOGIC-004, LOGIC-006, LOGIC-008.
