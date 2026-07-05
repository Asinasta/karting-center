# LOGIC-006 — Оценка маршала после заезда

## Где используется

SCR-006, BS-004.

## API

- `POST /bookings/{bookingId}/marshal-rating`
- Тело: `{ stars: 1..5, comment?: string }`
- Ответ: обновлённая `Booking` с `marshal_rating`

## Правила eligibility

- Бронь принадлежит текущему клиенту
- `status` ∈ `{active, completed}`
- Бронь не отменена (`cancelled`, `late_cancel`, `cancelled_by_center`)
- `now >= slot.start_at`
- На бронь ещё нет `marshal_rating` (для POST)

## Редактирование

- `PATCH /bookings/{bookingId}/marshal-rating` — те же поля `{ stars, comment? }`
- Доступно, если `marshal_rating` уже есть и бронь по-прежнему eligible (см. выше)
- `created_at` сохраняется; меняются только `stars` и `comment`

## Удаление

- `DELETE /bookings/{bookingId}/marshal-rating`
- Доступно при тех же условиях, что и редактирование
- После удаления можно снова поставить новую оценку через POST

## Ошибки

| code | HTTP | Когда |
|------|------|-------|
| `already_rated` | 409 | Повторная оценка |
| `rating_not_eligible` | 422 | Бронь ещё не прошла или отменена |
| `validation_error` | 400/422 | Некорректные `stars` или слишком длинный `comment` |

## Агрегаты

`GET /marshals` возвращает `average_rating` и `rating_count` по всем оценкам маршала.
