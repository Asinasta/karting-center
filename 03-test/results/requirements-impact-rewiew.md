# Ревью требований: MVP Flutter-клиент «Апекс» (полное ТЗ `5-mobile-app-spec/`)

## 1. Резюме

Проведено сквозное ревью всего пакета аналитики `01-analysis/`: от брифа заказчика до детального ТЗ на 7 экранов (SCR-*), 4 шторки (BS-*), 11 переиспользуемых логик (LOGIC-*), модели данных, OpenAPI и сопоставления с реализацией в `client/` и `backend/`. MVP охватывает роль «Клиент»: публичный каталог слотов, OTP-вход, бронирование с выбором экипировки, мои записи, отмена, профиль, карта трассы, лояльность, оценка маршала и push-инфраструктуру.

Главный вывод: спецификация в целом согласована и достаточна для MVP, но содержит ряд **неподтверждённых заказчиком допущений** (порог отмены 2 ч, push за 24/2 ч, пороги лояльности), **внутренние противоречия по таймингу оценки маршала** и **расхождение карты навигации** в `feature-list.md` с фактическим поведением (гость попадает на SCR-002, а не на SCR-001). Реализация покрывает SCR/BS/LOGIC-001…010, но **LOGIC-011 (напоминание об оценке)** и **реальный push (FL-14)** остаются в backlog; backend на fixtures имеет поведенческие расхождения с OpenAPI по валидации фильтров, `deleteAccount` 409 и актуализации snapshot при отмене центром.

Ключевые риски: регресс статусов брони при изменении логики времени (BUG-001), нестабильность навигации при старте сессии (BUG-004), расхождение preview цены и финальной `price_total` из-за лояльности, отсутствие production-адаптера `ExistingBackendAdapter`.

---

## 2. Импакт-анализ — спецификация (`01-analysis/`)

### 2.1. Экраны и шторки

| Артефакт | Импакт | Источник |
| :-- | :-- | :-- |
| **SCR-001** Регистрация/вход | Точка входа для всех защищённых сценариев; OTP-flow, имя нового пользователя, return-intent к слоту/форме; ошибки `invalid_code`, `rate_limit`, `code_expired` | `01-analysis/5-mobile-app-spec/SCR-001-registration.md:9-21` |
| **SCR-002** Список заездов | Публичный каталог без auth; дефолт 7 дней (R-027); фильтры BS-001; таб «Запись»; empty state | `01-analysis/5-mobile-app-spec/SCR-002-slot-list.md:9-19`, `01-analysis/0-customer-brief/customer-brief.md:65-67` |
| **BS-001** Фильтры | Параметры `date_from/to`, `track_config_type[]`, `marshal_id[]`, `only_available`; справочник маршалов | `01-analysis/5-mobile-app-spec/BS-001-filters.md:5-14`, `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-005_Фильтрация-слотов.md:9-16` |
| **SCR-003** Карточка заезда | Детали слота, CTA «Записаться», карта BS-004; auth gate при записи | `01-analysis/5-mobile-app-spec/SCR-003-slot-card.md` |
| **SCR-004** Оформление | Степпер мест, счётчики экипировки, price preview, `Idempotency-Key`, OTP при гостевом входе | `01-analysis/5-mobile-app-spec/SCR-004-booking.md:9-21` |
| **BS-002** Успех записи | Финальный `price_total` из API; навигация к SCR-005/SCR-002; триггер push-разрешения | `01-analysis/5-mobile-app-spec/BS-002-booking-success.md:9-17` |
| **SCR-005** Мои записи | Пагинация, клиентская группировка предстоящие/прошедшие/отменённые; баннер LOGIC-011 | `01-analysis/5-mobile-app-spec/SCR-005-my-bookings.md:9-17` |
| **SCR-006** Детали брони | Snapshot слота, отмена BS-003, карта, оценка маршала LOGIC-010 | `01-analysis/5-mobile-app-spec/SCR-006-booking-details.md` |
| **BS-003** Подтверждение отмены | Предупреждение о поздней отмене; сервер определяет `cancelled` vs `late_cancel` | `01-analysis/5-mobile-app-spec/BS-003-cancel-confirm.md` |
| **BS-004** Карта трассы | `meeting_point`, координаты, `geometry`; текстовый fallback | `01-analysis/5-mobile-app-spec/BS-004-track-map.md` |
| **SCR-007** Профиль | Имя, телефон (OTP смена), лояльность, push, logout, delete account | `01-analysis/5-mobile-app-spec/SCR-007-profile.md` |

### 2.2. Переиспользуемые логики и зависимости

| LOGIC | Где используется (прямо) | Что ещё затрагивает (косвенный импакт) |
| :-- | :-- | :-- |
| **LOGIC-001** OTP | SCR-001, SCR-007 (смена телефона) | Auth gate SCR-003→004; refresh token (api-sequence сценарий 3); secure storage (NFR-18) | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-001_OTP-авторизация.md:5-19` |
| **LOGIC-002** Доступность | SCR-002, SCR-003, SCR-004 | `createBooking` 409/410/422; UI степпера; отображение «заполнено» на карточках | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-002_Расчёт-доступности.md:9-15` |
| **LOGIC-003** Цена | SCR-003, SCR-004, BS-002, SCR-006* | `price_total` в истории; расхождение с LOGIC-009 (скидка не в preview) | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-003_Расчёт-цены.md:5-16` |
| **LOGIC-004** Отмена 2 ч | SCR-006, BS-003 | Удаление аккаунта (R-035); освобождение мест/проката; `late_cancel` в админку | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-004_Отмена-2-часа.md:9-18` |
| **LOGIC-005** Фильтры | SCR-002, BS-001 | `GET /slots` query; `GET /marshals` для справочника | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-005_Фильтрация-слотов.md:9-16` |
| **LOGIC-006** Карта | SCR-003, SCR-006, BS-004 | TrackConfig.geometry; meeting_point; NFR-23 fallback | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-006_Карта-трассы.md:9-11` |
| **LOGIC-007** Push | SCR-007, BS-002 | `registerPushToken`; FR-33/FR-51; deep link → SCR-006 | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-007_Push-разрешение.md:9-15` |
| **LOGIC-008** Состояния | Все SCR/BS | NFR-24 offline stale; запрет мутаций офлайн | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-008_Состояния-экрана.md:9-17` |
| **LOGIC-009** Лояльность | SCR-007, SCR-004, BS-002* | `createBooking` server-side discount; `GET /profile` | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-009_Лояльность.md:9-28` |
| **LOGIC-010** Оценка маршала | SCR-006 | `POST/PATCH/DELETE marshal-rating`; eligibility; агрегаты `GET /marshals` | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-010_Оценка-маршала.md:13-43` |
| **LOGIC-011** Напоминание | SCR-005 | `GET /notifications`; расширение LOGIC-007; push `rate_marshal` | `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-011_Напоминание-оценки-маршала.md:11-28` |

\* Односторонние ссылки: LOGIC-003 указывает SCR-006, но SCR-006 не перечисляет LOGIC-003; LOGIC-009 указывает BS-002, но BS-002 не описывает скидку.

### 2.3. API, модель данных, требования

| Компонент | Импакт | Источник |
| :-- | :-- | :-- |
| **OpenAPI** (21 operationId) | auth, slots, marshals, bookings, profile, notifications — единый контракт для client/backend | `01-analysis/api/redocly.yaml:2-14`, `01-analysis/5-mobile-app-spec/feature-list.md:28-41` |
| **Модель Booking** | Snapshot слота, `seat_gear[]`, статусы, `marshal_rating`, `price_total` | `01-analysis/4-design/data-model.md:64-96`, `01-analysis/api/bookings/models.yaml:35-79` |
| **Модель Slot** | `free_seats`, `free_rental_gear`, `capacity_cap`, статус `cancelled` | `01-analysis/4-design/data-model.md:45-62` |
| **FR/NFR** | 55 FR + 26 NFR покрывают весь MVP-скоуп | `01-analysis/2-requirements/functional-requirements.md`, `01-analysis/2-requirements/non-functional-requirements.md` |
| **Use cases / user stories** | UC-10 (оценка), UC-11 (лояльность) привязаны к LOGIC-009/010 | `01-analysis/2-requirements/use-cases.md` |

### 2.4. Пробелы в спецификации

| Пробел | Описание |
| :-- | :-- |
| Дизайн-бриф SCR-007 | В `3-design-brief/` есть SCR-001…006, BS-001…004, но **нет отдельного дизайн-брифа SCR-007** (только упоминание в `design-review.md`) |
| Web/desktop в домене | `01-analysis/README.md:28` заявляет iOS/Android/web/desktop; `domain-description.md:50` — только iOS/Android |
| `can_rate_marshal` | Упоминается в LOGIC-011 (`01-analysis/5-mobile-app-spec/09_Логики/LOGIC-011_Напоминание-оценки-маршала.md:16`), но не определён в LOGIC-010 или OpenAPI |
| Push deep-link контракт | LOGIC-007 описывает переход на SCR-006, но payload push не специфицирован в OpenAPI |
| Статус `active` после старта | Не описан явный переход `active` → `completed` в ТЗ экранов; только в data-model (`01-analysis/4-design/data-model.md:119-123`) |

---

## 3. Импакт-анализ — Flutter-клиент (`client/`)

| Компонент | Реализация | Импакт / статус | Источник |
| :-- | :-- | :-- | :-- |
| **SCR-001** | `auth/presentation/auth_screen.dart` | OTP, имя, consent, return intent | Реализован |
| **SCR-002** | `slots/presentation/slot_list_screen.dart` | Публичный список, фильтры, offline cache | Реализован |
| **BS-001** | `slots/presentation/filters_sheet.dart` | LOGIC-005 через `SlotFilter` | Реализован |
| **SCR-003** | `slot_details_screen.dart` + `slot_card.dart` | Публичный просмотр, auth gate | Реализован |
| **SCR-004** | `booking/presentation/booking_form_screen.dart` | Idempotency-Key, preview, loyalty hint | Реализован |
| **BS-002** | `booking/presentation/booking_success_sheet.dart` | API `price_total`; push hook в form, не в sheet | Реализован |
| **SCR-005** | `booking/presentation/booking_list_screen.dart` | Группировка, `effectiveBookingStatus` (BUG-001 fix) | Реализован; **LOGIC-011 отсутствует** |
| **SCR-006** | `booking/presentation/booking_details_screen.dart` | Cancel, map, marshal rating | Реализован |
| **BS-003** | `booking/presentation/cancel_confirm_sheet.dart` | LOGIC-004 preview | Реализован |
| **BS-004** | `map/presentation/track_map_sheet.dart` | **Частично**: иллюстрация + внешняя карта, без SDK | Частично |
| **SCR-007** | `profile/presentation/profile_screen.dart` | Loyalty, phone OTP, logout, delete | Реализован |
| **Роутинг** | `app/app_router.dart` | Auth gate на `/bookings*`, `/profile`, `/slots/:id/book`; гость → `/slots` | `client/lib/app/app_router.dart:15-67` |
| **Сессия** | `session/session_controller.dart` | JWT refresh, secure storage, splash check | `client/lib/features/session/` |
| **Domain policies** | `booking/domain/booking_policies.dart` | LOGIC-002, 003, 004, 010 | `client/lib/features/booking/domain/booking_policies.dart:4-153` |
| **Push (LOGIC-007)** | `notifications/push_service.dart` | **Stub**: флаг «спрашивали», токен всегда null | `client/lib/features/notifications/push_service.dart:39-65` |
| **Notifications (LOGIC-011)** | — | **Не реализовано**: нет репозитория `GET /notifications` | `client/README.md` (backlog) |
| **Offline cache** | `core/cache/local_cache.dart` | In-memory only; не персистентный | Отклонение от NFR-24 (полный offline stale) |
| **Архитектура** | features/*/data, domain, presentation | Нет слоя `application/` из плана CMP | `02-development/CMP_CLIENT_IMPLEMENTATION_PLAN.md` |

### Ключевые code-level расхождения с ТЗ

1. **Стартовая навигация**: `feature-list.md:11-13` — нет refresh → SCR-001; реализация — гость на SCR-002 (`app_router.dart:49-50`), что согласуется с SCR-002 (`SCR-002-slot-list.md:11`) и планом FL-03.
2. **SCR-004 степпер**: UI использует `AvailabilityPolicy.maxSeats` (LOGIC-002), но текст ТЗ «до всех свободных» (`SCR-004-booking.md:9`) не упоминает `capacity_cap`.
3. **Price preview + loyalty**: `BookingPricePreviewCalculator` поддерживает discount (`booking_policies.dart:49`), но LOGIC-003 формула без скидки.
4. **BUG-001 fix**: `effectiveBookingStatus()` синхронизирует UI с временем старта (`docs/bugs/BUG-001-past-booking-shows-active-status.md:19-22`).
5. **BUG-004 fix**: post-frame `checkSession()` (`docs/bugs/BUG-004-session-check-during-build.md:19-20`).

---

## 4. Импакт-анализ — Backend (`backend/`)

| Компонент | Реализация | Импакт / статус | Источник |
| :-- | :-- | :-- | :-- |
| **Роутеры** | auth, slots, marshals, bookings, profile, notifications | 21/21 operationId совпадают с OpenAPI | `backend/app/routers/`, `backend/app/contract_check.py` |
| **Контракты Pydantic** | `backend/app/contracts/` | Зеркалят OpenAPI models.yaml | `backend/app/contracts/` |
| **Fixtures adapter** | `backend/app/adapters/fixtures.py` | MVP data source; атомарность бронирования, idempotency, loyalty | Реализован |
| **Existing adapter** | `backend/app/adapters/existing.py` | **Stub**: все методы `NotImplementedError` | `backend/app/adapters/existing.py:28-126` |
| **Домен** | `policies.py`, `loyalty.py` | Отмена 2 ч, `maybe_complete_booking_status`, tier скидки | `backend/app/domain/` |
| **Тесты** | ~66 тестов в 14 файлах | auth, bookings, cancel, concurrency, ratings, notifications | `backend/tests/` |

### Расхождения OpenAPI ↔ backend (поведенческие)

| Область | OpenAPI / ТЗ | Backend fixtures | Severity |
| :-- | :-- | :-- | :-- |
| Валидация фильтров слотов | `400 Invalid filters` при невалидном `track_config_type` | Невалидные значения → пустой список без 400 | medium — `01-analysis/api/slots/api.yaml:35-40`, `backend/app/routers/slots.py:22` |
| `deleteAccount` 409 | 409 при необрабатываемом состоянии брони | Всегда 204; авто-отмена активных броней | medium — `01-analysis/api/profile/api.yaml:50-55`, `backend/app/adapters/fixtures.py:965-993` |
| Snapshot refresh при отмене центром | `BookingSlotSnapshot` status/cancel_reason «may be refreshed» | Snapshot фиксируется при создании; seed вручную меняет `cancelled_by_center` | medium — `01-analysis/api/bookings/models.yaml:78-79`, `backend/app/adapters/fixtures.py:481-496` |
| Contract-check | TC-10: «схемы без расхождений» | Проверяются только routes/operationId, не схемы | low — `docs/tasks/TASK-04-test-cases.md:28`, `backend/app/contract_check.py` |
| Pydantic vs domain errors | Смешение 400/422 | FastAPI validation → 400; domain → 422 | low — `backend/README.md:106-110` |

### Пробелы тестового покрытия backend

- HTTP-тест скидки лояльности в `createBooking` (TC-17 — только unit)
- Фильтр `marshal_id` (TC-14 — только client `toQuery()`)
- `slot_started` на create (422) — unit only
- `cancelled_by_center` — seed без явного assertion
- `GET /notifications` gating по `ride_end` — базовый list test only
- Security: `/notifications`, marshal-rating routes не в `test_security.py`

---

## 5. Связанные зависимости и контекст

### 5.1. Цепочка «бронирование»

```
SCR-002/003 (публичный) → auth gate → SCR-004 → POST /bookings
  → LOGIC-002 (места/прокат) + LOGIC-003 (цена) + LOGIC-009 (скидка server-side)
  → BS-002 → LOGIC-007 (push prompt) → SCR-005/002
```

Затрагивает: `Idempotency-Key` (NFR в api-sequence), JWT session, `GET /profile` для loyalty preview.

### 5.2. Цепочка «отмена»

```
SCR-005 → SCR-006 → BS-003 → POST /bookings/{id}/cancel
  → LOGIC-004 (2 ч, server decides) → обновление free_seats/free_rental_gear
```

Связано с удалением аккаунта (R-035, `LOGIC-004:14`), отменой центром (R-008, FR-46, push FR-51).

### 5.3. Цепочка «оценка маршала»

```
SCR-006 (LOGIC-010) ← eligibility: status, start_at, no rating
LOGIC-011 → GET /notifications → баннер SCR-005 → SCR-006
```

Конфликт тайминга: LOGIC-010 разрешает оценку с `start_at`, LOGIC-011 напоминает после `start_at + duration_min`.

### 5.4. Планы разработки

- `02-development/CMP_CLIENT_IMPLEMENTATION_PLAN.md` — FL-00…FL-15; FL-14 push и FL-15 integration tests — не завершены
- `02-development/BE_IMPLEMENTATION_PLAN.md` — fixtures MVP; production adapter — backlog

### 5.5. Известные баги (риск регресса)

| ID | Зона | Root cause | Файлы |
| :-- | :-- | :-- | :-- |
| BUG-001 | SCR-005/006 статус | `active` после старта + UI без `effectiveBookingStatus` | `docs/bugs/BUG-001-past-booking-shows-active-status.md:15-22` |
| BUG-002 | SCR-007 loyalty card | Overflow на узком viewport | `docs/bugs/BUG-002-loyalty-card-overflow.md` |
| BUG-003 | SCR-002/003 chips | Chip overflow без ellipsis | `docs/bugs/BUG-003-slot-card-chip-overflow.md` |
| BUG-004 | Splash/session | `notifyListeners` during GoRouter build | `docs/bugs/BUG-004-session-check-during-build.md:15-20` |

Любое изменение группировки броней, статусов API или splash-flow должно перепроверять эти сценарии (TC-21, TC-19, TC-20).

### 5.6. Числа из брифа (канон)

- 14 картов, ≤8 на новичковый — `01-analysis/0-customer-brief/customer-brief.md:22`
- Расписание на неделю — `01-analysis/0-customer-brief/customer-brief.md:22`, R-027

### 5.7. Предположения (не канон заказчика)

- Отмена 2 ч — `01-analysis/1-elicitation/customer-questions.md:68`, R-021
- Push 24/2 ч — `01-analysis/1-elicitation/customer-questions.md:79`, R-006
- Лояльность tier/проценты — `01-analysis/1-elicitation/customer-questions.md:119`, R-036
- Потолок опытного заезда 14 — `01-analysis/1-elicitation/customer-questions.md:61`

---

## 6. Расхождения платформ Flutter (iOS / Android / Web)

| Тема | iOS | Android | Web | Источник / факт |
| :-- | :-- | :-- | :-- | :-- |
| **Целевые платформы в ТЗ** | Да (NFR-4) | Да (NFR-4) | Заявлен в README анализа | `01-analysis/2-requirements/non-functional-requirements.md:13`, `01-analysis/README.md:28` vs `domain-description.md:50` (только mobile) |
| **Secure storage токенов** | Keychain via `flutter_secure_storage` | EncryptedSharedPreferences | Web: ограниченная защита (localStorage-level) | `01-analysis/5-mobile-app-spec/README.md:13`, NFR-18 |
| **Push (LOGIC-007)** | APNs (не подключён) | FCM (не подключён) | Нет системного push | `client/lib/features/notifications/push_service.dart:54-65` — stub на всех платформах |
| **API base URL** | localhost / device | `10.0.2.2` для эмулятора | `localhost:8080` | `client/lib/core/config/api_config.dart:16-24` |
| **Карта трассы (BS-004)** | Внешняя Yandex/карты | Аналогично | То же | `client/lib/map/presentation/track_map_sheet.dart` — без embedded SDK |
| **Системный back** | Swipe back | Hardware/gesture back | Browser back → GoRouter | Стандартное поведение Flutter; deep link из push не реализован |
| **BUG-004** | — | — | Проявлялся на web (chrome) | `docs/bugs/BUG-004-session-check-during-build.md:5` |
| **Touch targets / a11y** | ≥44pt (NFR-25) | ≥44pt | Меньший приоритет для MVP | `01-analysis/2-requirements/non-functional-requirements.md:33` |

**Вывод:** платформенный анализ возможен; критичное различие — push и secure storage на web; карта и push одинаково деградируют до fallback/stub на всех платформах в текущей сборке.

---

## 7. Противоречия и тонкости

1. **Тайминг оценки маршала: старт заезда vs конец заезда**  
   LOGIC-010: `now >= slot.start_at` (`01-analysis/5-mobile-app-spec/09_Логики/LOGIC-010_Оценка-маршала.md:18`). LOGIC-011: `now >= slot.start_at + duration_min` (`01-analysis/5-mobile-app-spec/09_Логики/LOGIC-011_Напоминание-оценки-маршала.md:17`). SCR-006: «после старта заезда». Клиент может оценить во время заезда, напоминание — после. **Severity: high**

2. **Карта навигации: обязательный вход vs публичный каталог**  
   `feature-list.md:11-13` — нет refresh → SCR-001. SCR-002 и R-029 — публичный просмотр без auth. Реализация и SCR-002 согласованы с R-029, но mermaid в feature-list вводит в заблуждение. **Severity: medium**

3. **SCR-004 «до всех свободных» vs LOGIC-002 `capacity_cap`**  
   Текст SCR-004 (`SCR-004-booking.md:9`) не ограничивает степпер `min(free_seats, capacity_cap)` (`LOGIC-002_Расчёт-доступности.md:9`). Клиент применяет cap в коде; формулировка ТЗ неполная. **Severity: medium**

4. **Price preview без лояльности vs server `price_total` со скидкой**  
   LOGIC-003: `price * seats + rental * count` (`LOGIC-003_Расчёт-цены.md:10`). LOGIC-009: скидка только server-side (`LOGIC-009_Лояльность.md:28`). Риск «скачка» цены на BS-002. Клиент частично компенсирует discount в preview. **Severity: medium**

5. **OTP error codes: SCR-001 vs LOGIC-001**  
   SCR-001: `code_expired`, `retry_after` (`SCR-001-registration.md:17`). LOGIC-001: без `code_expired` (`LOGIC-001_OTP-авторизация.md:19`). **Severity: low**

6. **LOGIC-011 в SCR-005 vs backlog реализации**  
   SCR-005 применяет LOGIC-011 (`SCR-005-my-bookings.md:17`), но LOGIC-011:28 — «Flutter backlog». **Severity: medium**

7. **Snapshot брони vs актуализация при отмене центром**  
   data-model и OpenAPI: status/cancel_reason snapshot «могут актуализироваться» (`01-analysis/4-design/data-model.md:87`, `01-analysis/api/bookings/models.yaml:78-79`). Backend fixtures: snapshot frozen at create. **Severity: medium**

8. **`deleteAccount` 409 в OpenAPI vs always 204 в backend**  
   Spec: 409 при необрабатываемом состоянии (`01-analysis/api/profile/api.yaml:50-55`). Fixtures: auto-cancel + 204. **Severity: medium**

9. **Невалидные фильтры слотов: 400 vs пустой список**  
   OpenAPI: 400 (`01-analysis/api/slots/api.yaml:35-40`). Backend: silent empty. **Severity: low**

10. **Дизайн-бриф: отсутствует SCR-007**  
    Все остальные экраны имеют пары spec/design-brief; профиль — только mobile-app-spec. **Severity: low**

11. **Платформенный скоуп: web/desktop в README vs только mobile в domain**  
    `01-analysis/README.md:28` vs `01-analysis/1-elicitation/domain-description.md:50`. **Severity: low**

12. **`can_rate_marshal` не определён**  
    LOGIC-011 ссылается на поле, отсутствующее в LOGIC-010 и API. **Severity: medium**

13. **Переход `active` → `completed`**  
    Не описан в SCR; BUG-001 показал рассинхрон. Backend добавил `maybe_complete_booking_status` на read-path — не задокументировано в ТЗ экранов. **Severity: medium**

14. **BS-002 и LOGIC-009**  
    LOGIC-009 включает BS-002, но экран успеха не показывает применённую скидку tier. **Severity: low**

15. **Приоритет при расхождениях**  
    README: `5-mobile-app-spec/` > `3-design-brief/` (`01-analysis/README.md:6`). Design-brief foundations: неавторизованная зона = SCR-001 (`00-foundations.md:17`) — расходится с R-029. **Severity: low**

---

## 8. Вопросы к BA

1. **Когда клиент может оценить маршала: с момента старта заезда или после его окончания (`start_at + duration_min`)?**  
   Контекст: LOGIC-010 vs LOGIC-011 vs UX «оцените после заезда» из брифа. Приоритет: **high**. Категория: **contradiction**.

2. **Подтвердить порог ранней отмены: 2 часа до старта (ровно 2 ч = ранняя)?**  
   Контекст: R-021 помечен как предположение; в брифе только пример «за 10 минут» как поздняя (`01-analysis/0-customer-brief/customer-brief.md:24`). Приоритет: **high**. Категория: **missing**.

3. **Подтвердить пороги лояльности: ≥3 заезда → 10%, ≥8 → 15% (R-036)?**  
   Контекст: в брифе нет чисел; влияет на SCR-004 preview и BS-002. Приоритет: **high**. Категория: **missing**.

4. **Должен ли price preview на SCR-004 включать скидку лояльности до `createBooking`?**  
   Контекст: LOGIC-003 не включает скидку; LOGIC-009 применяет server-side. Приоритет: **medium**. Категория: **ambiguity**.

5. **Обновлять ли `Booking.slot` snapshot при отмене слота центром, или достаточно `Booking.status` + `cancel_reason`?**  
   Контекст: OpenAPI description vs frozen snapshot в backend. Приоритет: **medium**. Категория: **ambiguity**.

6. **Нужен ли `deleteAccount` → 409 для «необрабатываемых» броней, или auto-cancel всегда допустим?**  
   Контекст: OpenAPI 409 vs текущая реализация. Приоритет: **medium**. Категория: **contradiction**.

7. **Исправить mermaid в `feature-list.md`: гость без refresh → SCR-002, а не SCR-001?**  
   Контекст: R-029, SCR-002, текущая реализация. Приоритет: **medium**. Категория: **clarification**.

8. **LOGIC-011 (баннер «Оцените маршала») — Must для MVP или backlog?**  
   Контекст: SCR-005 ссылается на LOGIC-011; реализация backlog. Приоритет: **medium**. Категория: **ambiguity**.

9. **Показывать ли средний рейтинг маршала клиентам в каталоге (SCR-002/003)?**  
   Контекст: вопрос 15 в customer-questions помечен как предположение; публичные рейтинги вне скоупа (`domain-description.md:64`). Приоритет: **low**. Категория: **clarification**.

10. **Подтвердить лимит опытного заезда: все 14 картов?**  
    Контекст: предположение R-001 в customer-questions. Приоритет: **medium**. Категория: **missing**.

11. **Сколько прокатных комплектов экипировки; показывать ли «прокат закончился» при наличии мест?**  
    Контекст: R-003, FR-14; открытый вопрос в design-review. Приоритет: **medium**. Категория: **missing**.

12. **Web/desktop — в скоупе MVP или только iOS/Android?**  
    Контекст: README анализа vs domain-description. Приоритет: **low**. Категория: **clarification**.

13. **Нужен ли дизайн-бриф для SCR-007 (профиль, лояльность, удаление аккаунта)?**  
    Контекст: пробел в `3-design-brief/`. Приоритет: **low**. Категория: **missing**.

14. **Какой контракт payload для push (отмена центром, reminder, rate_marshal) и deep link на SCR-006?**  
    Контекст: LOGIC-007/011 без OpenAPI схемы push payload. Приоритет: **medium**. Категория: **missing**.

15. **Должен ли backend переводить `active` → `completed` автоматически при `now > start_at + duration`, или только по событию из инфраструктуры?**  
    Контекст: BUG-001, read-path sync в fixtures. Приоритет: **medium**. Категория: **ambiguity**.

---

## 9. Комментарии к ревью

### Сильные стороны спецификации

- Чёткая граница MVP: только роль «Клиент», read-only слоты (`01-analysis/0-customer-brief/customer-brief.md:46-63`).
- Хорошая декомпозиция: SCR/BS + LOGIC + feature-list + OpenAPI + data-model образуют прослеживаемую цепочку.
- Критичные сценарии (бронирование, отмена, refresh token) задокументированы в api-sequence с кодами ошибок.
- Предположения явно помечены в `customer-questions.md` — снижает риск выдачи допущений за ответы Дениса.

### Рекомендации до разработки / перед релизом

1. **Синхронизировать LOGIC-010 и LOGIC-011** по единому моменту eligibility; обновить SCR-006 и тесты TC-16.
2. **Обновить `feature-list.md` mermaid** и `3-design-brief/00-foundations.md:17` под R-029 (гостевой каталог).
3. **Дополнить LOGIC-003** формулой preview со скидкой или явно указать, что скидка видна только после API.
4. **Зафиксировать политику `active` → `completed`** в data-model и SCR-005/006.
5. **Закрыть LOGIC-011** или снять ссылку из SCR-005 до реализации.
6. **Согласовать FL-14 push plugin** и контракт deep link; иначе FR-51 (Must) не выполним на устройстве.
7. **Расширить contract-check** валидацией схем или пометить TC-10 как «routes only».
8. **Подготовить дизайн-бриф SCR-007** — зона риска overflow (BUG-002) и удаление аккаунта.
9. **Получить от заказчика подтверждение** по вопросам 2, 3, 10, 11 из раздела 8 до freeze требований.

### Охват ревью

| Источник | Статус |
| :-- | :-- |
| `01-analysis/0-customer-brief/` | Прочитан |
| `01-analysis/1-elicitation/` | Прочитан |
| `01-analysis/2-requirements/` | Прочитан (BR, FR, NFR, use cases) |
| `01-analysis/3-design-brief/` | Прочитан (design-review, foundations, экраны) |
| `01-analysis/4-design/` | Прочитан (data-model, api-sequence) |
| `01-analysis/5-mobile-app-spec/` | Прочитан полностью (SCR, BS, LOGIC, feature-list, README) |
| `01-analysis/api/` | Сверен с backend contracts |
| `client/` | Code-level анализ проведён |
| `backend/` | Code-level анализ проведён |
| `docs/bugs/`, `docs/tasks/TASK-04-test-cases.md` | Учтены |
| `02-development/*_PLAN.md` | Учтены через субагентов |

*Дата ревью: 2026-07-07. Ревьюер: QA/BA (автоматизированный проход по артефактам).*
