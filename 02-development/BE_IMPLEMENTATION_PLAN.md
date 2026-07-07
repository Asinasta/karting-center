# План реализации BE для «Апекс»

## Решение по реализации

BE для MVP — это клиентский API-слой поверх существующей инфраструктуры картинг-центра. Он отдаёт мобильному приложению REST JSON API по OpenAPI из `01-analysis/api`, валидирует запросы клиента, нормализует ошибки и передаёт доменные операции в существующий backend через адаптеры.

В рамках MVP не делаем новую production-БД, админку, интерфейс маршала, интерфейс владельца, CRUD расписания, онлайн-оплату и авто-погоду. Оценки маршалов, программа лояльности и push-инфраструктура входят в MVP по брифу заказчика.

## Стек

Используемые технологии в `backend/`:

- **Python 3.11+**
- **FastAPI** — HTTP API
- **Uvicorn** — локальный запуск (`manage.py run`)
- **Pydantic** + **pydantic-settings** — DTO по контракту и конфигурация из `.env`
- **PyJWT** — access/refresh токены
- **PyYAML** — проверка контракта (`manage.py contract-check`)
- **pytest** + **httpx** — тесты API
- **ruff** — lint/format

## Ограничения и архитектура

- Формат API: REST JSON.
- Контракт: OpenAPI 3.1 из `01-analysis/api`.
- Авторизация: JWT Bearer access token + refresh token.
- Публичные endpoints без Bearer: `listSlots`, `getSlot`, `listMarshals`.
- Персональные endpoints и мутации требуют Bearer auth и owner-check.
- Конфигурация: переменные окружения (`.env`).
- Логи: структурированные JSON-логи.
- Локальная разработка и тесты: in-memory **fixtures adapter**; production — адаптер к существующему backend (`existing`, пока stub).
- Тесты: HTTP/API, adapter fixtures, concurrency для создания и отмены брони.

## State ownership

BE-слой — фасад поверх существующей инфраструктуры, но план должен явно определить, где хранится состояние, которое требуется клиентскому API:

| Состояние | MVP fixtures/dev | Production-вариант |
|---|---|---|
| OTP входа и смены телефона, попытки, rate limit | In-memory fixtures с управляемым временем | Delegated existing backend или отдельное short-lived хранилище API-слоя |
| Refresh token lifecycle, revoke/delete account | In-memory token store | Delegated existing backend или persistent token store |
| `Idempotency-Key` для `createBooking` | In-memory idempotency records | Existing backend idempotency или persistent API-side records с TTL |
| Push tokens | In-memory upsert по client+platform+device | Existing backend push registry или API-side store |
| `BookingSlotSnapshot` | Fixtures snapshot на момент брони | Existing backend возвращает snapshot по контракту API |

Перед реализацией production adapter нужно зафиксировать: каждое состояние делегируется существующему backend или хранится в API-слое. Нельзя оставлять это неявным в handler logic.

## Источники для разработки

- API-контракт: `01-analysis/api/redocly.yaml`.
- Модель данных: `01-analysis/4-design/data-model.md`.
- Use cases: `01-analysis/2-requirements/use-cases.md`.
- ТЗ мобильного клиента: `01-analysis/5-mobile-app-spec/`.

## API-методы

| Домен | operationId | Endpoint | Что делает |
|---|---|---|---|
| Auth | `sendOtp` | `POST /auth/otp` | Отправляет OTP на телефон |
| Auth | `verifyOtp` | `POST /auth/verify` | Проверяет OTP, выполняет вход или регистрацию |
| Auth | `refreshToken` | `POST /auth/refresh` | Обновляет пару токенов |
| Slots | `listSlots` | `GET /slots` | Публично возвращает список заездов с фильтрами |
| Slots | `getSlot` | `GET /slots/{slotId}` | Публично возвращает карточку заезда |
| Marshals | `listMarshals` | `GET /marshals` | Публично возвращает read-only справочник маршалов |
| Bookings | `createBooking` | `POST /bookings` | Создаёт бронь с `Idempotency-Key` |
| Bookings | `listBookings` | `GET /bookings` | Возвращает записи текущего клиента |
| Bookings | `getBooking` | `GET /bookings/{bookingId}` | Возвращает детали брони текущего клиента |
| Bookings | `cancelBooking` | `POST /bookings/{bookingId}/cancel` | Отменяет бронь целиком |
| Bookings | `rateMarshal` | `POST /bookings/{bookingId}/marshal-rating` | Создаёт оценку маршала |
| Bookings | `updateMarshalRating` | `PATCH /bookings/{bookingId}/marshal-rating` | Обновляет оценку |
| Bookings | `deleteMarshalRating` | `DELETE /bookings/{bookingId}/marshal-rating` | Удаляет оценку |
| Profile | `getProfile` | `GET /profile` | Возвращает профиль (включая loyalty) |
| Profile | `updateProfile` | `PATCH /profile` | Обновляет имя |
| Profile | `sendPhoneChangeOtp` | `POST /profile/phone-change/otp` | Отправляет OTP на новый телефон |
| Profile | `verifyPhoneChange` | `POST /profile/phone-change/verify` | Подтверждает новый телефон и обновляет профиль |
| Profile | `deleteAccount` | `DELETE /profile` | Удаляет аккаунт |
| Profile | `registerPushToken` | `POST /profile/push-token` | Регистрирует push token |
| Notifications | `listNotifications` | `GET /notifications` | Pending-уведомления (напоминание об оценке маршала) |

## Структура проекта

```text
backend/
  app/
    contracts/     Pydantic DTO по OpenAPI
    domain/        Сущности, политики, loyalty
    ports.py       Абстрактные порты
    adapters/      fixtures (in-memory) и existing (stub)
    routers/       HTTP-эндпоинты; operationId = имя функции
    security.py    JWT access/refresh
    errors.py      ApiError + реестр кодов
    main.py        Фабрика app, middleware, /healthz
    contract_check.py
  tests/
  manage.py
  README.md
  .env.example
```

## Правила реализации

- Один пункт плана = один вертикальный срез: контракт, handler, сервис, адаптер, тесты.
- Любое изменение публичного API начинается с правки `01-analysis/api`.
- Contract models должны соответствовать `01-analysis/api`.
- `Slot`, `TrackConfig`, `Marshal` доступны клиенту только на чтение.
- `listSlots`, `getSlot`, `listMarshals` публичны и не требуют Bearer auth.
- `bookings`, `profile`, `phone-change`, `push-token` требуют Bearer auth.
- `getBooking`, `cancelBooking`, `listBookings` всегда фильтруются по текущему `client_id`; чужие брони не возвращаются.
- `createBooking` всегда проверяет доступность на стороне BE.
- `Booking.slot` возвращается как `BookingSlotSnapshot`, а не live-модель доступности слота.
- `price_total`, тип отмены, статус заезда и доступность мест — серверные значения.
- `updateProfile` обновляет только имя; смена телефона идёт через `sendPhoneChangeOtp` и `verifyPhoneChange`.
- Задача считается готовой только после тестов и сверки endpoint с OpenAPI.

## Security matrix

| Группа | Endpoints | Доступ | Проверки |
|---|---|---|---|
| Public catalog | `GET /slots`, `GET /slots/{slotId}`, `GET /marshals` | Guest/client | Валидация query/path, без персональных данных |
| Auth | `POST /auth/*` | Guest/client | OTP TTL, retry_after, attempts limit |
| Bookings | `POST/GET /bookings*` | Client | Bearer auth, owner-check, idempotency, no overbooking |
| Profile | `GET/PATCH/DELETE /profile` | Client | Bearer auth, только текущий клиент |
| Phone change | `POST /profile/phone-change/*` | Client | Bearer auth, OTP на новый номер, старый номер активен до успеха |
| Push token | `POST /profile/push-token` | Client | Bearer auth, upsert по client+platform+device |

## План работ

- [ ] [BE-00. Каркас проекта](#be-00-каркас-проекта)
- [ ] [BE-01. Подключение OpenAPI-контракта](#be-01-подключение-openapi-контракта)
- [ ] [BE-02. HTTP-ядро, ошибки и валидация](#be-02-http-ядро-ошибки-и-валидация)
- [ ] [BE-03. Слой адаптеров и state ownership](#be-03-слой-адаптеров-и-state-ownership)
- [ ] [BE-04. Авторизация и сессия](#be-04-авторизация-и-сессия)
- [ ] [BE-05. Публичный каталог: заезды и маршалы](#be-05-публичный-каталог-заезды-и-маршалы)
- [ ] [BE-06. Создание брони](#be-06-создание-брони)
- [ ] [BE-07. Список и детали броней](#be-07-список-и-детали-броней)
- [ ] [BE-08. Отмена брони](#be-08-отмена-брони)
- [ ] [BE-09. Профиль, смена телефона и push token](#be-09-профиль-смена-телефона-и-push-token)
- [ ] [BE-10. Контрактная сверка ошибок и валидации](#be-10-контрактная-сверка-ошибок-и-валидации)
- [ ] [BE-11. Тесты](#be-11-тесты)
- [ ] [BE-12. Передача в разработку](#be-12-передача-в-разработку)

## BE-00. Каркас проекта

Сделать:

- Создать `backend/` по структуре выше.
- Добавить команды проекта: `format`, `lint`, `test`, `run`.
- Добавить `GET /healthz` вне публичного OpenAPI.
- Добавить `.env.example`:
  - `APP_ENV=dev`;
  - `HTTP_ADDR=:8080`;
  - `JWT_ACCESS_SECRET=dev-access-secret`;
  - `JWT_REFRESH_SECRET=dev-refresh-secret`;
  - `BACKEND_ADAPTER=fixtures`.

Готово когда:

- Команда `run` стартует API.
- `GET /healthz` возвращает `200`.
- Команда `test` проходит.

## BE-01. Подключение OpenAPI-контракта

Сделать:

- Подключить OpenAPI-контракты для `auth`, `slots`, `bookings`, `profile`, `marshals`.
- Создать contract models в `src/contracts`.
- Сохранить `operationId` как имена handler methods/functions.
- Добавить команду проверки соответствия handlers и OpenAPI.

Готово когда:

- Проверка контракта подтверждает, что все endpoints из OpenAPI представлены в handlers.
- Request/response DTO соответствуют OpenAPI schemas.

## BE-02. HTTP-ядро, ошибки и валидация

Сделать:

- Подключить HTTP router.
- Реализовать middleware:
  - request id;
  - access log;
  - panic recovery;
  - JSON content type;
  - Bearer auth для защищённых endpoints;
  - public endpoint skip-list для `listSlots`, `getSlot`, `listMarshals`.
- Реализовать единый writer для success/error ответов.
- Реализовать validator request body/query/path по OpenAPI DTO.
- Реализовать `Error` writer в формате `{ "code": "...", "message": "...", "details": {...} }`.
- Поддержать `retry_after` для rate limit ошибок.

Готово когда:

- Невалидный JSON возвращает `400`.
- Отсутствующий Bearer token на защищённых endpoints возвращает `401 unauthorized`.
- Публичные endpoints доступны без Bearer token.
- Panic внутри handler возвращает `500 server_error`.
- Все handlers возвращают только error codes из `01-analysis/api/common/models.yaml`.

## BE-03. Слой адаптеров и state ownership

Сделать:

- Описать порты:
  - `AuthPort`;
  - `SlotPort`;
  - `MarshalPort`;
  - `BookingPort`;
  - `ProfilePort`;
  - `PushTokenPort`.
- Для каждого порта описать ownership состояния: API-layer или existing backend.
- Реализовать `fixtures` adapter для dev/test.
- Реализовать `existing` adapter как интеграционный слой к существующему backend.
- Fixtures должны содержать:
  - доступный заезд;
  - заполненный заезд;
  - заезд, отменённый центром;
  - заезд с местами, но без прокатной экипировки;
  - активную бронь;
  - завершённую бронь;
  - бронь со статусом `cancelled_by_center`;
  - `BookingSlotSnapshot`;
  - idempotency replay и idempotency conflict;
  - phone-change OTP happy/error cases;
  - push token registration и token refresh.

Готово когда:

- Handlers работают через порты, а не напрямую через fixtures.
- Dev API полностью работает с `BACKEND_ADAPTER=fixtures`.
- `existing` adapter реализует все методы портов.
- Для каждого stateful сценария явно понятно, кто владеет состоянием.

## BE-04. Авторизация и сессия

Сделать:

- `sendOtp`: принять phone, нормализовать, создать dev OTP в fixtures adapter.
- `verifyOtp`: проверить phone/code, создать клиента для нового телефона, вернуть `TokenPair`.
- `refreshToken`: принять `refresh_token`, вернуть новую пару токенов.
- Access token TTL: 15 минут.
- Refresh token TTL: 30 дней.
- Refresh token rotation/revoke: старый refresh после успешного refresh не должен оставаться бесконечно валидным, если production ownership не делегирован existing backend.
- Dev OTP: `0000`, только при `APP_ENV=dev` и `BACKEND_ADAPTER=fixtures`.
- API не стартует в non-dev окружении с dev JWT secrets.

Готово когда:

- Новый клиент проходит phone -> OTP -> TokenPair.
- Существующий клиент получает TokenPair без повторного создания профиля.
- Неверный OTP возвращает `invalid_code`.
- Частые OTP-запросы возвращают `rate_limit` с `retry_after`.
- Refresh с невалидным token возвращает `unauthorized`.
- Удалённый аккаунт и revoked refresh token не могут обновить сессию.

## BE-05. Публичный каталог: заезды и маршалы

Сделать:

- `listSlots`: поддержать `date_from`, `date_to`, `track_config_type[]`, `marshal_id[]`, `only_available`.
- Период по умолчанию: ближайшие 7 дней.
- Сортировка: `start_at ASC`.
- `getSlot`: вернуть полную модель `Slot`.
- `listMarshals`: вернуть список `Marshal`.
- Endpoints публичные: Bearer auth не требуется.

Готово когда:

- `only_available=true` скрывает заполненные и отменённые заезды.
- `only_available=false` возвращает заполненные и отменённые заезды с данными для disabled CTA.
- Фильтры комбинируются через AND между группами.
- Запросы без Authorization возвращают `200`, если данные доступны.

## BE-06. Создание брони

Сделать:

- Требовать `Idempotency-Key`.
- Request body: `slot_id`, `seat_gear[]`.
- Вычислять `seats_count = len(seat_gear)`.
- Вычислять `rental_count = count(rental)`.
- Валидировать `1 <= seats_count <= min(free_seats, capacity_cap)`.
- Отклонять отменённый слот через `slot_cancelled`.
- Отклонять начавшийся слот через `slot_started`.
- Отклонять нехватку мест/экипировки через `slot_full`.
- Отклонять повторную активную бронь клиента на тот же слот через `double_booking`.
- Для `double_booking` возвращать `booking_id` существующей активной брони в `Error.details`.
- Создавать/возвращать `Booking` с `BookingSlotSnapshot` и серверным `price_total`.
- Повтор с тем же `Idempotency-Key` и тем же payload возвращает тот же результат.
- Повтор с тем же `Idempotency-Key`, но другим payload возвращает документированную ошибку `validation_error` или `double_booking` по контрактному решению.

Готово когда:

- Повтор того же запроса с тем же `Idempotency-Key` возвращает ту же бронь.
- Изменённый payload с тем же ключом не создаёт вторую бронь.
- Параллельные create-запросы не создают overbooking в fixtures.
- `Booking.slot` в ответе не содержит live-поля доступности (`free_seats`, `free_rental_gear`) как источник истории.

## BE-07. Список и детали броней

Сделать:

- `listBookings`: вернуть брони текущего клиента с `limit`, `offset`, `pagination`.
- Default `limit`: 20.
- `getBooking`: вернуть только бронь текущего клиента.
- В ответ включить `BookingSlotSnapshot`, `price_total`, `status`, `cancel_reason`.
- Чужая бронь возвращает `403 forbidden` или `404 not_found` по контрактному решению, но никогда не раскрывает данные.

Готово когда:

- Клиент не получает чужие брони.
- Пагинация возвращает `items` и `pagination`.
- Бронь `cancelled_by_center` содержит `cancel_reason`.
- Исторические брони отображают snapshot параметров слота, а не live-доступность.

## BE-08. Отмена брони

Сделать:

- `cancelBooking`: отменять только активную бронь текущего клиента.
- Если `start_at - now >= 2h`: вернуть статус `cancelled`.
- Если `start_at - now < 2h`: вернуть статус `late_cancel`.
- Ровно 2 часа считать ранней отменой.
- После старта возвращать `slot_started`.
- Повторную отмену возвращать как `already_cancelled`.
- Поздняя отмена не освобождает места/экипировку и передаётся в существующую инфраструктуру/админку через adapter.

Готово когда:

- Тесты границ проходят для `2h+1s`, `2h`, `1h59m59s`, after start.
- Ранняя отмена освобождает места и экипировку в fixtures.
- Поздняя отмена не освобождает места и экипировку.
- Adapter получает событие/операцию, позволяющую существующей инфраструктуре видеть `late_cancel`.

## BE-09. Профиль, смена телефона и push token

Сделать:

- `getProfile`: вернуть текущего клиента.
- `updateProfile`: обновить только `name`.
- `sendPhoneChangeOtp`: принять `new_phone`, проверить уникальность, отправить OTP на новый номер.
- `verifyPhoneChange`: проверить `new_phone` и `code`, обновить телефон только после успешного OTP.
- До успешного `verifyPhoneChange` старый телефон остаётся активным логином.
- `deleteAccount`: применить обычную политику отмен к активным броням, анонимизировать завершённые, инвалидировать refresh token.
- `registerPushToken`: upsert token по client+platform+device.

Готово когда:

- Обновление профиля возвращает обновлённый `Profile`.
- `PATCH /profile` не принимает и не меняет `phone`.
- Смена телефона с неверным OTP возвращает `invalid_code`.
- Смена телефона на занятый номер возвращает `phone_already_used`.
- Удалённый аккаунт не может использовать старый refresh token.
- Повторная регистрация push token обновляет существующее значение.

## BE-10. Контрактная сверка ошибок и валидации

Сделать:

- Использовать только error codes из `01-analysis/api/common/models.yaml`:
  - `slot_full`;
  - `double_booking`;
  - `slot_cancelled`;
  - `slot_started`;
  - `already_cancelled`;
  - `invalid_code`;
  - `rate_limit`;
  - `phone_already_used`;
  - `unauthorized`;
  - `forbidden`;
  - `not_found`;
  - `validation_error`;
  - `server_error`.
- Формат ответа: `{ "code": "...", "message": "...", "details": {...} }`.
- `slot_full.details` содержит актуальные `free_seats` и `free_rental_gear`.
- `double_booking.details` содержит `booking_id` существующей активной брони.
- `rate_limit` содержит `retry_after`.

Готово когда:

- У каждого endpoint есть минимум один error test.
- Ни один handler не возвращает недокументированный error code.
- Error responses соответствуют OpenAPI schemas.

## BE-11. Тесты

Сделать:

- Unit tests:
  - availability;
  - cancellation boundary;
  - price total;
  - OTP validation;
  - phone-change OTP;
  - idempotency replay/conflict.
- HTTP tests для всех `operationId`.
- Concurrency tests для `createBooking`.
- Idempotency tests для `createBooking`.
- Security tests:
  - public catalog without token;
  - protected endpoints without token;
  - booking owner-check.

Готово когда:

- Команда `test` проходит.
- Тесты покрывают все Must use cases из `01-analysis/2-requirements/use-cases.md`.

## BE-12. Передача в разработку

Сделать:

- `backend/README.md`:
  - setup;
  - env;
  - run;
  - tests;
  - fixtures mode.
- Добавить smoke commands:
  - send OTP;
  - verify OTP;
  - list slots;
  - create booking;
  - cancel booking;
  - get profile.

Готово когда:

- Разработчик запускает API с чистого checkout.
- Smoke flow работает с fixtures adapter.
- В README нет пропущенных команд.
- Smoke flow покрывает public catalog -> auth gate -> booking -> my bookings -> phone change -> cancel -> delete/logout.
