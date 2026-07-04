# План реализации BE для «Апекс»

## TOC / Todo реализации

- [ ] [BE-00. Создать каркас backend-приложения](#be-00-создать-каркас-backend-приложения)
- [ ] [BE-01. Подключить OpenAPI как контракт](#be-01-подключить-openapi-как-контракт)
- [ ] [BE-02. Реализовать общую HTTP-инфраструктуру](#be-02-реализовать-общую-http-инфраструктуру)
- [ ] [BE-03. Спроектировать storage-слой и dev seed data](#be-03-спроектировать-storage-слой-и-dev-seed-data)
- [ ] [BE-04. Реализовать Auth: OTP и сессии](#be-04-реализовать-auth-otp-и-сессии)
- [ ] [BE-05. Реализовать Profile и push-token](#be-05-реализовать-profile-и-push-token)
- [ ] [BE-06. Реализовать read-only каталог слотов и маршалов](#be-06-реализовать-read-only-каталог-слотов-и-маршалов)
- [ ] [BE-07. Реализовать атомарное создание брони](#be-07-реализовать-атомарное-создание-брони)
- [ ] [BE-08. Реализовать список и детали броней](#be-08-реализовать-список-и-детали-броней)
- [ ] [BE-09. Реализовать отмену брони](#be-09-реализовать-отмену-брони)
- [ ] [BE-10. Довести контрактные ошибки и валидацию](#be-10-довести-контрактные-ошибки-и-валидацию)
- [ ] [BE-11. Добавить тесты доменных правил и API](#be-11-добавить-тесты-доменных-правил-и-api)
- [ ] [BE-12. Подготовить локальный запуск и документацию разработчика](#be-12-подготовить-локальный-запуск-и-документацию-разработчика)
- [ ] [BE-13. Финальная проверка готовности BE](#be-13-финальная-проверка-готовности-be)

## Стек приложения

- Язык и рантайм: Go 1.23+.
- API: REST JSON API, OpenAPI-first, контракты из `01-analysis/api/redocly.yaml` и доменных `api.yaml`.
- HTTP: `net/http` + `chi`, middleware для auth, request id, recovery, logging.
- OpenAPI: `oapi-codegen` для генерации типов/серверных интерфейсов с сохранением `operationId`.
- Storage: PostgreSQL 16 для локальной разработки и интеграционных тестов; существующая инфраструктура центра остаётся black-box источником истины на production-интеграции.
- Миграции и SQL: `goose` для миграций, `sqlc` для типобезопасных запросов без ORM.
- Auth: phone/OTP flow, JWT Bearer access token, refresh token, интерфейс SMS/OTP provider; dev-реализация пишет OTP в лог.
- Тесты: Go unit/integration tests, concurrency tests для booking/cancel.
- Runtime: Docker Compose для API + PostgreSQL, конфигурация через env, structured logs через `slog`.

## Функционал и endpoints

| Домен | operationId | Endpoint | Функционал |
|---|---|---|---|
| Auth | `sendOtp` | `POST /auth/otp` | Отправка SMS OTP по телефону |
| Auth | `verifyOtp` | `POST /auth/verify` | Проверка OTP, вход/регистрация, выдача `TokenPair` |
| Auth | `refreshToken` | `POST /auth/refresh` | Обновление access token по `refresh_token` |
| Slots | `listSlots` | `GET /slots` | Список слотов/заездов с фильтрами |
| Slots | `getSlot` | `GET /slots/{slotId}` | Карточка слота/заезда |
| Marshals | `listMarshals` | `GET /marshals` | Read-only справочник маршалов для фильтров |
| Bookings | `createBooking` | `POST /bookings` | Атомарное создание брони, `Idempotency-Key` |
| Bookings | `listBookings` | `GET /bookings` | История записей текущего клиента |
| Bookings | `getBooking` | `GET /bookings/{bookingId}` | Детали своей брони |
| Bookings | `cancelBooking` | `POST /bookings/{bookingId}/cancel` | Отмена брони целиком по правилу ранней/поздней отмены |
| Profile | `getProfile` | `GET /profile` | Профиль текущего клиента |
| Profile | `updateProfile` | `PATCH /profile` | Обновление имени и телефона |
| Profile | `deleteAccount` | `DELETE /profile` | Удаление аккаунта, отмена активных броней, анонимизация истории |
| Profile | `registerPushToken` | `POST /profile/push-token` | Регистрация push token Flutter-приложения |

Служебные endpoints для эксплуатации можно добавить вне клиентского API: `GET /healthz`, `GET /readyz`. Если они попадают в публичный контракт, сначала обновить OpenAPI.

## Правила для ralph loop

- Один пункт ниже = одна итерация: взять контекст, реализовать минимальный вертикальный срез, добавить/обновить тесты, прогнать указанную проверку.
- Любое изменение публичного API начинается с правки `01-analysis/api/*` и проверки OpenAPI lint/bundle.
- Не добавлять marshal/admin/owner UI или API, schedule CRUD, slot creation/editing, online payment, ratings, loyalty, auto-weather cancellation и no-show.
- Клиентский API не должен создавать или редактировать `Slot`, `TrackConfig`, `Marshal`.
- Для `createBooking` не полагаться на FE: сервер валидирует места, прокатную экипировку, статус слота, цену и время.
- Каждый пункт считается готовым только после тестов и сверки с `01-analysis/2-requirements/use-cases.md`.

## Декомпозиция BE

### BE-00. Создать каркас backend-приложения

Сделать:

- Создать `backend/` с Go module, `cmd/api/main.go`, `internal/config`, `internal/http`, `internal/domain`, `internal/storage`, `internal/service`.
- Добавить Makefile или `task`-команды для `fmt`, `lint`, `test`, `run`, `migrate`.
- Поднять Docker Compose для PostgreSQL и локального API.
- Добавить `.env.example` без секретов.

Готово, когда:

- `go test ./...` проходит в `backend/`.
- API стартует локально и отдаёт служебный health endpoint.
- Новый разработчик может запустить проект по README.

### BE-01. Подключить OpenAPI как контракт

Сделать:

- Настроить генерацию Go DTO/server interfaces из доменов `auth`, `slots`, `bookings`, `profile`, `marshals`.
- Сохранить имена `operationId` в структуре handler methods.
- Добавить проверку, что generated code не редактируется вручную.
- Завести contract test, который сверяет зарегистрированные routes с OpenAPI.

Готово, когда:

- OpenAPI lint/bundle проходит после установки зависимостей.
- `go generate ./...` или выбранная команда codegen воспроизводит generated files.
- `go test ./...` проходит.

### BE-02. Реализовать общую HTTP-инфраструктуру

Сделать:

- Middleware: request id, access log, panic recovery, JSON content type, auth extractor.
- Единый error mapper под `01-analysis/api/common/models.yaml`: `code`, `message`, `details`.
- Валидация request body/query/path с возвратом `400`, `401`, `403`, `404`, `409`, `410`, `422`, `429`, `5xx` по контрактам.
- Централизованная обработка `Authorization: Bearer <access_token>`.

Готово, когда:

- Handler tests проверяют формат ошибок и status codes.
- Неверный JSON, отсутствующий Bearer token и неизвестный path возвращают контрактные ответы.

### BE-03. Спроектировать storage-слой и dev seed data

Сделать:

- Таблицы `clients`, `auth_sessions`, `otp_codes`, `track_configs`, `marshals`, `slots`, `bookings`, `idempotency_keys`, `push_tokens`.
- `track_configs`, `marshals`, `slots` сделать read-only для клиентского API; данные для dev/test загружать seed-миграцией или fixtures.
- Для `bookings` сохранить `status in (active,cancelled,late_cancel,cancelled_by_center,completed)`, `seats_count`, `rental_count`, `seat_gear`, `price_total`, `created_at`, `cancelled_at`.
- Для `slots` хранить данные, достаточные для атомарного расчёта `free_seats` и `free_rental_gear`.
- Добавить индексы по `phone`, `slot_id`, `client_id`, `start_at`, `status`, idempotency key.

Готово, когда:

- Миграции применяются на пустую PostgreSQL.
- Integration test поднимает схему, создаёт seed slots и читает их через repository.
- Seed data содержит минимум новичковый и опытный заезд, полный слот, отменённый центром слот и слот с нехваткой прокатной экипировки.

### BE-04. Реализовать Auth: OTP и сессии

Сделать:

- `POST /auth/otp`: нормализовать телефон, ограничить частоту запросов, создать OTP с TTL.
- `POST /auth/verify`: проверить OTP, создать клиента при первом входе, вернуть `TokenPair`.
- `POST /auth/refresh`: проверить refresh token и выдать новую пару токенов.
- Хранить OTP только в hash-виде; dev OTP provider пишет код в лог.
- Реализовать ошибки `invalid_code`, `rate_limit`, `unauthorized`.

Готово, когда:

- Unit tests покрывают валидный код, неверный код, истёкший код, повторное использование, rate limit.
- Integration test проходит полный login flow.
- Refresh flow восстанавливает запрос после `401`.

### BE-05. Реализовать Profile и push-token

Сделать:

- `GET /profile`: вернуть только текущего клиента.
- `PATCH /profile`: обновить имя и телефон; смена телефона требует OTP-подтверждения, если выбран такой поток реализации.
- `DELETE /profile`: удалить/анонимизировать ПДн, инвалидировать сессии, отменить активные брони.
- `POST /profile/push-token`: сохранить token и platform (`ios`, `android`) для текущего клиента.
- Повторная регистрация push token должна обновлять запись без дублей.

Готово, когда:

- Tests проверяют доступ только к своему профилю, смену данных и удаление аккаунта.
- Удалённый аккаунт не может использовать старый token.
- Push token можно зарегистрировать повторно без создания дублей.

### BE-06. Реализовать read-only каталог слотов и маршалов

Сделать:

- `GET /slots`: фильтры `date_from`, `date_to`, `track_config_type[]`, `marshal_id[]`, `only_available`; сортировка по `start_at ASC`.
- По умолчанию возвращать ближайшие 7 дней, если клиент не передал период.
- `GET /slots/{slotId}`: вернуть слот с `track_config.geometry`, meeting point, marshal, prices, availability.
- `GET /marshals`: read-only справочник маршалов для фильтра.
- Для `only_available=false` показывать слоты без мест с корректным `free_seats=0`; не скрывать их на сервере без параметра.

Готово, когда:

- Integration tests покрывают все фильтры, пустой результат и 404 для неизвестного слота.
- Клиентские поля совпадают с OpenAPI models.
- Отменённые центром и заполненные слоты различимы для UI.

### BE-07. Реализовать атомарное создание брони

Сделать:

- `POST /bookings` принимать `Idempotency-Key` и сохранять результат для безопасного retry.
- Валидировать `seat_gear` в диапазоне `1..3`; `seats_count = len(seat_gear)`.
- Рассчитать `rental_count` как число `rental` в `seat_gear`.
- В транзакции заблокировать слот, проверить `status=scheduled`, `start_at` в будущем, свободные места и прокатную экипировку.
- Предотвратить double booking текущего клиента на тот же слот.
- Уменьшать доступность слота только после успешного создания брони.
- Возвращать `409 slot_full`/`double_booking`, `410 slot_cancelled`, `422 slot_started` с `details.free_*`, где применимо.

Готово, когда:

- Concurrency test с параллельными `createBooking` не допускает `free_seats < 0` и `free_rental_gear < 0`.
- Повтор с тем же `Idempotency-Key` возвращает тот же результат без второй брони.
- Изменённый payload с тем же ключом возвращает контрактную ошибку или безопасно отклоняется.

### BE-08. Реализовать список и детали броней

Сделать:

- `GET /bookings`: вернуть только брони текущего клиента, поддержать `limit`, `offset`.
- `GET /bookings/{bookingId}`: вернуть только свою бронь с вложенными slot/track_config/marshal данными для `SCR-006`.
- Не хранить отдельный UI-статус `past`; прошедшие брони определяются по `slot.start_at` и `completed`.
- Возвращать отменённые центром брони со статусом `cancelled_by_center` и `cancel_reason`.

Готово, когда:

- Tests проверяют запрет доступа к чужой брони, 404 для неизвестной, пагинацию и статусы.
- В ответах нет неописанных статусов.

### BE-09. Реализовать отмену брони

Сделать:

- `POST /bookings/{bookingId}/cancel`: в транзакции заблокировать booking и slot.
- Отмена доступна только до `slot.start_at`.
- Если до старта `>= 2h`, статус `cancelled`, места и прокатная экипировка возвращаются.
- Если до старта `< 2h`, статус `late_cancel`, места и прокатная экипировка не возвращаются.
- Ровно `2h` считать ранней отменой.
- Повторную отмену возвращать как контрактную ошибку `409 already_cancelled`.

Готово, когда:

- Unit tests покрывают границы времени: `2h+1s`, `2h`, `1h59m59s`, после старта.
- Concurrency test параллельных cancel не возвращает места дважды.

### BE-10. Довести контрактные ошибки и валидацию

Сделать:

- Зафиксировать machine codes из `01-analysis/api/common/models.yaml`: `slot_full`, `double_booking`, `slot_cancelled`, `slot_started`, `already_cancelled`, `invalid_code`, `rate_limit`, `unauthorized`, `server_error`.
- Проверить, что все handlers возвращают `application/json` и тело `Error` для ошибок.
- Добавить request validation для всех path/query/body параметров из OpenAPI.
- Добавить `details` для ошибок нехватки мест/проката там, где это помогает UI.

Готово, когда:

- Contract tests по каждому endpoint проверяют основные success/error статусы.
- OpenAPI examples не противоречат реальным ответам.

### BE-11. Добавить тесты доменных правил и API

Сделать:

- Unit tests для domain services: availability, price source, cancellation rule, auth OTP.
- Repository integration tests на PostgreSQL.
- HTTP integration tests на все endpoints.
- Race/concurrency tests для create/cancel.

Готово, когда:

- `go test ./...` проходит стабильно.
- Критичные сценарии из `01-analysis/2-requirements/use-cases.md` имеют API-level тест.

### BE-12. Подготовить локальный запуск и документацию разработчика

Сделать:

- `backend/README.md`: setup, env vars, migrations, seed, run, tests.
- Docker Compose profiles для app, db, migrations.
- Описать, что `track_configs`, `marshals`, `slots` read-only и в dev заполняются seed data.
- Добавить команды smoke-check для auth, list slots, create booking, cancel booking.

Готово, когда:

- Новый разработчик поднимает API с нуля по README.
- Все команды из README проверены локально.

### BE-13. Финальная проверка готовности BE

Сделать:

- Прогнать OpenAPI lint/bundle.
- Прогнать Go format/lint/test/race.
- Прогнать HTTP integration tests.
- Сверить endpoints с таблицей в начале файла и с `01-analysis/5-mobile-app-spec/*.md`.

Готово, когда:

- Все endpoints из OpenAPI реализованы.
- Booking/cancel выдерживают параллельные запросы без double booking и overbooking.
- Нет реализации функционала вне MVP scope без явного изменения требований.
