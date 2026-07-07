# TASK-03. Реализовать хотя бы 3 фичи

## Цель

Реализовать минимум три end-to-end фичи клиентского MVP по спецификации `01-analysis/5-mobile-app-spec/` и планам `02-development/`. Фактически реализовано **10 фич + заглушка push**.

## Исходные требования

- Feature list: `01-analysis/5-mobile-app-spec/feature-list.md` (F-001…F-010).
- User stories: US-1, US-2, US-3, US-5, US-9, US-10, US-14.
- Use cases: UC-1 (запись), UC-2 (отмена), UC-3 (OTP-вход) и др.

## Реализованные фичи

Реализовано **10 end-to-end фич** по `feature-list.md` (F-001…F-008, F-010…F-012) и **заглушка push** (F-009). Ниже — только то, что есть в `backend/` и `client/`.

### Фича 1. Публичный список заездов (F-002, US-2, SCR-002)

| | |
|---|---|
| **Симптом/цель** | Клиент видит слоты на 7 дней без входа |
| **API** | `GET /slots` (без токена) |
| **Клиент** | `slot_list_screen.dart`, `slot_card.dart`, `slot_repository.dart` |
| **Backend** | `routers/slots.py`, `FixturesAdapter.list_slots` |

Состояния: Loading, Content, Empty, Error, Offline stale. Сортировка по `start_at`. Disabled CTA для полных/отменённых.

### Фича 2. Фильтры заездов (F-003, US-3, BS-001)

| | |
|---|---|
| **Симптом/цель** | Сузить список по периоду, типу трассы, маршалу, «только свободные» |
| **API** | `GET /slots` (`date_from`, `date_to`, `track_config_type[]`, `marshal_id[]`, `only_available`), `GET /marshals` |
| **Клиент** | `filters_sheet.dart`, `slot_filter.dart`, `period_preset.dart`, `marshal_repository.dart` |
| **Backend** | `routers/slots.py`, `routers/marshals.py`, фильтрация в `FixturesAdapter.list_slots` |

Пресеты периода: Сегодня, Завтра, Ближайшие 7 дней (дефолт), На этой неделе, В эти выходные, Ближайший месяц, Выбрать даты.

### Фича 3. Карточка заезда (F-004, US-4, SCR-003)

| | |
|---|---|
| **Симптом/цель** | Детали слота перед записью |
| **API** | `GET /slots/{slotId}` (без токена) |
| **Клиент** | `slot_details_screen.dart` |
| **Backend** | `routers/slots.py`, `FixturesAdapter.get_slot` |

CTA «Записаться» с auth gate для гостя. Ссылка на карту трассы (BS-004).

### Фича 4. OTP-авторизация (F-001, US-1, SCR-001)

| | |
|---|---|
| **Симптом/цель** | Вход по телефону и SMS-коду; регистрация нового клиента отдельным шагом |
| **API** | `POST /auth/otp`, `POST /auth/verify`, `POST /auth/refresh` |
| **Клиент** | `auth_screen.dart`, `session_repository.dart`, `session_controller.dart`, `splash_screen.dart` |
| **Backend** | `routers/auth.py`, dev OTP `0000` |

Шаги: телефон → код → (для нового клиента) имя и согласие. Auth gate: гость при записи / «Мои записи» / «Профиль» → `/auth?return=...` → возврат после OTP.

### Фича 5. Создание брони (F-005, US-5–8, SCR-004, BS-002)

| | |
|---|---|
| **Симптом/цель** | Запись на заезд: места, своя/прокатная экипировка, превью цены |
| **API** | `POST /bookings` + `Idempotency-Key` |
| **Клиент** | `booking_form_screen.dart`, `booking_success_sheet.dart`, `booking_policies.dart` |
| **Backend** | `routers/bookings.py`, `ensure_bookable`, idempotency store |

Обработка: `slot_full`, `double_booking` (переход к существующей брони), `slot_cancelled`, `slot_started`. После первой брони — запрос разрешения push (заглушка).

### Фича 6. Мои записи (F-006, US-9, SCR-005)

| | |
|---|---|
| **Симптом/цель** | Список броней клиента, группы upcoming / past / cancelled |
| **API** | `GET /bookings` |
| **Клиент** | `booking_list_screen.dart`, `booking_repository.dart` |
| **Backend** | `routers/bookings.py`, `FixturesAdapter.list_bookings` |

### Фича 7. Детали брони и отмена (F-007, US-10, SCR-006, BS-003)

| | |
|---|---|
| **Симптом/цель** | Карточка брони (snapshot слота), ранняя/поздняя отмена |
| **API** | `GET /bookings/{bookingId}`, `POST /bookings/{bookingId}/cancel` |
| **Клиент** | `booking_details_screen.dart`, `cancel_confirm_sheet.dart`, `CancellationPolicy` |
| **Backend** | `routers/bookings.py`, `cancellation_kind`, `FixturesAdapter.cancel_booking` |

### Фича 8. Оценка маршала (F-011, US-16, SCR-006)

| | |
|---|---|
| **Симптом/цель** | Оценка 1–5 и комментарий после завершённого заезда |
| **API** | `POST/PATCH/DELETE /bookings/{bookingId}/marshal-rating` |
| **Клиент** | `marshal_rating_section.dart` (в `booking_details_screen.dart`) |
| **Backend** | `routers/bookings.py`, рейтинг в `FixturesAdapter` |

### Фича 9. Профиль и лояльность (F-008, F-012, US-14, US-17, SCR-007)

| | |
|---|---|
| **Симптом/цель** | Имя, телефон, карточка лояльности, выход, удаление аккаунта |
| **API** | `GET/PATCH/DELETE /profile`, `POST /profile/phone-change/otp`, `POST /profile/phone-change/verify` |
| **Клиент** | `profile_screen.dart`, `phone_change_sheet.dart`, `loyalty_card.dart`, `profile_repository.dart` |
| **Backend** | `routers/profile.py`, скидка лояльности в `create_booking` |

Смена телефона — OTP на новый номер (диалог). Лояльность отображается из `getProfile`.

### Фича 10. Карта трассы (F-010, BS-004)

| | |
|---|---|
| **Симптом/цель** | Схема трассы и точка сбора |
| **API** | данные слота: `geometry`, `meeting_point`, координаты |
| **Клиент** | `track_map_sheet.dart` (`CustomPaint` + ссылка на внешнюю карту) |
| **Backend** | поля в `Slot` / fixtures seed |

### Фича 11. Push-уведомления — заглушка (F-009, частично)

| | |
|---|---|
| **Симптом/цель** | Подготовка к push: регистрация token, запрос разрешения после первой брони |
| **API** | `POST /profile/push-token`; `GET /notifications` — **только backend**, клиент не вызывает |
| **Клиент** | `push_service.dart` (`LocalFlagPushService` — без реального push-плагина) |
| **Backend** | `routers/profile.py`, `routers/notifications.py`, in-memory push registry |

Реальная доставка push и экран уведомлений **не реализованы** (открытый вопрос в `client/README.md`).

## Промпты

### План реализации фич

```
Довести Flutter-клиент «Апекс» до MVP по CMP_CLIENT_IMPLEMENTATION_PLAN.md (FL-00…FL-15).

Реализуй по порядку:
- FL-04: публичный список заездов SCR-002;
- FL-05: фильтры BS-001 / LOGIC-005;
- FL-02/03: OTP SCR-001, сессия, auth gate, return intent;
- FL-07/08: форма брони SCR-004, idempotency, превью цены;
- FL-09…11: мои записи, детали, отмена, оценка маршала;
- FL-12/13: карта трассы, профиль, лояльность.

Все API-модели сверяй с 01-analysis/api/. Не выдумывай поля и коды ошибок.
```

### Фильтры и фикстуры

```
Оптимальный набор пресетов периода: Сегодня, Завтра, В эти выходные,
Ближайшие 7 дней (дефолт), Ближайший месяц (+30 дней), Выбрать даты.

Добавь в fixtures слоты с 5 маршалами и разными датами,
чтобы можно было проверить каждый пресет.
```

### UX и адаптив

```
[скриншот] Сделай диалоги «Имя» и «Смена телефона» в едином стиле.

Реализуй адаптивную обёртку для модальных окон — mobile и web/desktop.

Auth flow: сначала код из SMS, потом для нового пользователя — имя и согласие.
```

### Документация фич

```
@docs/tasks/TASK-03-features.md — напиши все фичи, которые реализованы
в backend/ и client/. Для каждой: цель, API, файлы клиента/backend.
```

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
