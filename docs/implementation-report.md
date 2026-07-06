# Отчёт о реализации клиента

> Исторический отчёт о завершении Flutter MVP. Актуальная документация поставки — [`docs/tasks/`](tasks/).

## Что реализовано

**Ядро** (`client/lib/core/`):

- `ApiClient` — GET/POST/PATCH/DELETE, публичные запросы без токена, защищённые с `Authorization: Bearer`; на `401` ровно один refresh и один повтор запроса.
- `AppFailure` — типизированные ошибки со всеми кодами из `common/models.yaml`, `retry_after`, `double_booking.details.booking_id`, русские UI-сообщения.
- `SecureTokenStorage` (flutter_secure_storage), `LocalCache` — in-memory read-only fallback для offline stale.

**Фичи** (структура `data / domain / presentation`):

- `session` — `SessionRepository`, `SessionController`, splash с проверкой сессии.
- `auth` — SCR-001: OTP, имя для нового клиента, countdown по `retry_after`.
- `slots` — SCR-002, BS-001, SCR-003.
- `booking` — SCR-004, BS-002, SCR-005, SCR-006 (включая оценку маршала LOGIC-010), BS-003.
- `map` — BS-004: geometry + fallback.
- `profile` — SCR-007: имя, смена телефона OTP, `LoyaltyCard` (LOGIC-009), logout, delete.
- `notifications` — `PushService` stub (FL-14); `GET /notifications` на клиенте — backlog (LOGIC-011).

**Роутер**: auth gate в go_router для `/slots/:id/book`, `/bookings*`, `/profile`.

## Закрытые пункты FL

FL-00…FL-13 — полностью. FL-14 — частично (инфраструктура push без плагина). FL-15 — `flutter analyze` и `flutter test` (29 unit-тестов на момент отчёта).

## Как проверить

См. [`RUN_LOCAL.md`](../RUN_LOCAL.md).

```bash
cd backend && python manage.py run
cd client && flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

Smoke: список → фильтры → карточка → OTP (`0000`) → бронь → мои записи → детали → оценка маршала → отмена → профиль (лояльность) → выход.
