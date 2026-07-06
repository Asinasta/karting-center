# LOGIC-009 — Программа лояльности

## Где используется

SCR-007, SCR-004, BS-002.

## Уровни

| completed_rides | tier | Скидка |
|-----------------|------|--------|
| ≥ 3 | `regular` | 10% |
| ≥ 8 | `vip` | 15% |

`completed_rides` — число броней со статусом `completed` (одна бронь = один заезд).

Пороги tier и проценты скидки — **предположение R-036** (не зафиксированы в брифе; реализация в `backend/app/domain/loyalty.py`).

## API

`GET /profile` возвращает:

- `completed_rides_count`
- `loyalty_tier` (`regular` | `vip` | null)
- `loyalty_discount_percent` (10 | 15 | null)

## Скидка при записи

Сервер применяет скидку к `price_total` при `createBooking`. Клиент может показывать предварительную скидку из профиля.
