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
| TC-16 | Оценка маршала | POST/PATCH/DELETE marshal-rating | Eligibility, already_rated | `test_marshal_ratings.py` |
| TC-17 | Лояльность | createBooking со скидкой tier | price_total со скидкой | `test_loyalty.py` |
| TC-18 | Loyalty preview | PricePolicy с discount | Формула LOGIC-009 | `booking_policies_test.dart` |
| TC-19 | Loyalty card layout | Viewport 320×480, text scale 2× | Нет overflow | `client/test/widgets/loyalty_card_test.dart` |
| TC-20 | Slot card chips layout | Узкий экран, длинный маршал | Чипы с ellipsis, нет overflow | `client/test/widgets/slot_card_test.dart` |
| TC-21 | Splash session check | Старт приложения, GoRouter + session | Нет `setState during build` | `client/test/widgets/splash_screen_test.dart` |

## Найденные и исправленные баги

| # | Документ | Кратко |
|---|---|---|
| 1 | [BUG-001-past-booking-shows-active-status.md](../bugs/BUG-001-past-booking-shows-active-status.md) | В «Прошедших» бронь показывала статус «Активна» |
| 2 | [BUG-002-loyalty-card-overflow.md](../bugs/BUG-002-loyalty-card-overflow.md) | Overflow карточки лояльности при a11y text scale |
| 3 | [BUG-003-slot-card-chip-overflow.md](../bugs/BUG-003-slot-card-chip-overflow.md) | Overflow чипов в карточке заезда |
| 4 | [BUG-004-session-check-during-build.md](../bugs/BUG-004-session-check-during-build.md) | `setState during build` при checkSession на splash |

## Промпты

### Первый прогон анализатора и тестов

```
PS ...\client> flutter analyze
PS ...\client> flutter test

(вывод: loyalty_card_test падает с RenderFlex overflow 162px;
flutter analyze — deprecated withOpacity, warning unnecessary_non_null_assertion)
```

### Баг со скриншотом (BUG-001)

```
[скриншот]
Тут баг: в «Прошедших» бронь со статусом «Активна».
```

### Overflow в списке заездов (BUG-003)

```
══╡ EXCEPTION: RenderFlex overflowed by X pixels on the right ╞══
Row: .../slot_card.dart:169:14 (ChipText)
+ Leading widget consumes the entire tile width (ListTile)
```

### Ошибка при старте (BUG-004)

```
Uncaught DartError: setState() or markNeedsBuild() called during build.
Стек: splash_screen initState → checkSession → notifyListeners → Router
```

```
при чём тут notifyListeners()
```

## Проверка вручную

```bash
# Backend
cd backend
python manage.py contract-check
python manage.py test

# Client
cd client
flutter analyze
flutter test
```

Результат на момент сдачи:

- `contract-check` — OK.
- Backend pytest — все тесты проходят (~66).
- `flutter analyze` — 0 issues.
- `flutter test` — 34 теста passed.
- Smoke UI — список заездов и карточка проверены в браузере на `http://127.0.0.1:3000`.
