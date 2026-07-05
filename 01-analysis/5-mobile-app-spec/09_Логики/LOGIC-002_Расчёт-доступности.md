# LOGIC-002 — Расчёт доступности

## Где используется

SCR-002, SCR-003, SCR-004.

## Правила

- Доступное число мест для выбора: `max_seats = min(free_seats, track_config.capacity_cap)`.
- Прокатная экипировка считается отдельно: `rental_count <= free_rental_gear`.
- Клиент может предварительно ограничивать UI, но финальное решение принимает сервер.

## Ошибки

`slot_full`, `slot_cancelled`, `slot_started`.
