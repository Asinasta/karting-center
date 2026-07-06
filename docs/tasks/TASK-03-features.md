# TASK-03. Реализовать хотя бы 3 фичи

## Цель

Реализовать минимум три end-to-end фичи клиентского MVP по спецификации `01-analysis/5-mobile-app-spec/` и планам `02-development/`. Фактически реализовано **6 ключевых фич** (значительно больше минимума).

## Исходные требования

- Feature list: `01-analysis/5-mobile-app-spec/feature-list.md` (F-001…F-010).
- User stories: US-1, US-2, US-3, US-5, US-9, US-10, US-14.
- Use cases: UC-1 (запись), UC-2 (отмена), UC-3 (OTP-вход) и др.

## Реализованные фичи (≥3)

### Фича 1. Публичный список заездов (F-002, US-2, SCR-002)

| | |
|---|---|
| **Симптом/цель** | Клиент видит слоты на 7 дней без входа |
| **API** | `GET /slots` (без токена) |
| **Клиент** | `client/lib/features/slots/presentation/slot_list_screen.dart` |
| **Backend** | `backend/app/routers/slots.py`, `FixturesAdapter.list_slots` |

Состояния: Loading, Content, Empty, Error, Offline stale. Сортировка по `start_at`. Disabled CTA для полных/отменённых.

### Фича 2. OTP-авторизация (F-001, US-1, SCR-001)

| | |
|---|---|
| **Симптом/цель** | Вход по телефону и SMS-коду без пароля |
| **API** | `POST /auth/otp`, `POST /auth/verify`, `POST /auth/refresh` |
| **Клиент** | `auth_screen.dart`, `session_repository.dart`, `session_controller.dart` |
| **Backend** | `backend/app/routers/auth.py`, dev OTP `0000` |

Auth gate: гость при записи/«Мои записи»/«Профиль» → `/auth?return=...` → возврат после OTP.

### Фича 3. Создание брони (F-005, US-5–8, SCR-004, BS-002)

| | |
|---|---|
| **Симптом/цель** | Запись на заезд: 1–3 места, своя/прокатная экипировка |
| **API** | `POST /bookings` + `Idempotency-Key` |
| **Клиент** | `booking_form_screen.dart`, `booking_success_sheet.dart`, `booking_policies.dart` |
| **Backend** | `backend/app/routers/bookings.py`, `ensure_bookable`, idempotency store |

Обработка: `slot_full`, `double_booking` (переход к существующей брони), `slot_cancelled`, `slot_started`.

### Дополнительно (сверх минимума)

| Фича | US | Экран | Ключевые файлы |
|---|---|---|---|
| Фильтры | US-3 | BS-001 | `filters_sheet.dart`, `slot_filter.dart` |
| Карточка заезда | US-4 | SCR-003 | `slot_details_screen.dart` |
| Мои записи | US-9 | SCR-005 | `booking_list_screen.dart` |
| Отмена брони | US-10 | BS-003 | `cancel_confirm_sheet.dart`, `CancellationPolicy` |
| Профиль + лояльность | US-14, US-17 | SCR-007 | `profile_screen.dart`, `loyalty_card.dart` |
| Оценка маршала | US-16 | SCR-006 | `marshal_rating_section.dart`, `booking_repository.dart` |
| Карта трассы | F-010 | BS-004 | `track_map_sheet.dart` (geometry + fallback) |

## Промпты

- `docs/prompts/chat-04-backend-development.txt`
- `docs/prompts/chat-06-flutter-client-development.txt`

## Проверка вручную

См. `RUN_LOCAL.md`. Smoke-сценарий:

1. `http://127.0.0.1:3000` → список заездов (без входа).
2. Фильтры → применить/сбросить.
3. Карточка заезда → «Записаться» → OTP (`+7...`, код **0000**).
4. Форма брони → успех (BS-002).
5. «Мои записи» → детали → оценка маршала → отмена.
6. «Профиль» → карточка лояльности → смена имени → выход.

Автопроверки:

```bash
cd backend && python manage.py test
cd client && flutter analyze && flutter test
```

## Коммиты

- `feat(backend): add client API with fixtures adapter`
- `feat(client): implement MVP features FL-00 through FL-13`
