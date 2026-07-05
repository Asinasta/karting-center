# TASK-04. Сгенерировать тест-кейсы, найти и исправить от 1 до 3 багов

## Цель

Сформировать тест-кейсы для ключевых сценариев MVP, реализовать автотесты где возможно, найти и исправить 1–3 бага с документированием.

## Исходные требования

- NFR-8, NFR-9: атомарность бронирования, нет овербукинга.
- NFR-22: сценарий гонки при `createBooking`.
- UC-1 исключения E1–E6: `slot_full`, `double_booking`, idempotency.
- LOGIC-002, LOGIC-004: доступность мест, правило 2 часов отмены.
- FL-15 в `CMP_CLIENT_IMPLEMENTATION_PLAN.md`: unit-тесты policies, репозитории с mock HTTP.

## Тест-кейсы

| ID | Сценарий | Шаги | Ожидание | Автотест |
|---|---|---|---|---|
| TC-01 | Публичный список слотов | `GET /slots` без токена | 200, массив, сортировка по `start_at` | `test_catalog.py` |
| TC-02 | Фильтр only_available | `GET /slots?only_available=true` | Только слоты с местами | `test_catalog.py` |
| TC-03 | OTP вход (dev) | `POST /auth/otp` + `verify` code `0000` | TokenPair | `test_auth.py` |
| TC-04 | Создание брони | `POST /bookings` с `Idempotency-Key` | 201, `price_total` | `test_bookings.py` |
| TC-05 | Двойная бронь | Повтор на тот же слот | 409 `double_booking` + `booking_id` | `test_bookings.py` |
| TC-06 | Овербукинг / slot_full | Больше мест, чем свободно | 409 `slot_full` | `test_bookings.py` |
| TC-07 | Гонка бронирований | Параллельные `createBooking` | Нет переброни | `test_concurrency.py` |
| TC-08 | Ранняя отмена (≥2ч) | `cancelBooking` до старта | status `cancelled`, места возвращены | `test_cancellation.py` |
| TC-09 | Поздняя отмена (<2ч) | `cancelBooking` | status `late_cancel` | `test_cancellation.py` |
| TC-10 | Контракт OpenAPI | Все operationId и схемы | 0 расхождений | `manage.py contract-check` |
| TC-11 | maxSeats policy | `min(free, cap)` | Корректный лимит | `client/test/domain/booking_policies_test.dart` |
| TC-12 | Цена preview | seats × price + rental × count | Формула LOGIC-003 | `booking_policies_test.dart` |
| TC-13 | 401 → refresh → retry | Истёкший access token | Один refresh, повтор успешен | `client/test/data/repositories_test.dart` |
| TC-14 | Фильтры в query | `SlotFilter.toQuery()` | `track_config_type`, `marshal_id` | `repositories_test.dart` |
| TC-15 | Smoke UI (ручной) | Список → OTP → бронь → отмена | Полный flow без ошибок | Ручная проверка |

## Найденные и исправленные баги

| # | Документ | Кратко |
|---|---|---|
| 1 | [BUG-001-slot-filters-ignored.md](../bugs/BUG-001-slot-filters-ignored.md) | Клиент не передавал фильтры в `GET /slots` |
| 2 | [BUG-002-money-kopecks-lost.md](../bugs/BUG-002-money-kopecks-lost.md) | `Money.formatted` терял копейки |
| 3 | [BUG-003-no-session-check-and-auth-gate.md](../bugs/BUG-003-no-session-check-and-auth-gate.md) | Нет проверки сессии и auth gate |

## Промпты

- `docs/prompts/chat-06-flutter-client-development.txt` — ревизия клиента, исправление расхождений со спецификацией.
- Ручная проверка и баг с портом 3000 — в чате «Failed to bind web development server».

## Проверка вручную

```powershell
# Backend
cd backend
.\.venv\Scripts\python.exe manage.py contract-check
.\.venv\Scripts\python.exe manage.py test

# Client
cd client
flutter analyze
flutter test
```

Результат на момент сдачи:

- `contract-check` — OK.
- Backend pytest — все тесты проходят.
- `flutter analyze` — 0 issues.
- `flutter test` — 17 тестов passed.
- Smoke UI — список заездов и карточка проверены в браузере на `http://127.0.0.1:3000`.

## Коммиты

- `test(backend): add API and policy test suite`
- `test(client): add domain policies and repository tests`
- `docs(task-04): test cases and bug traceability`
- `fix(client): slot filters, money formatting, session auth gate` — исправления багов 1–3
