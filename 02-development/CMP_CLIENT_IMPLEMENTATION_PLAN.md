# План реализации Flutter-клиента для «Апекс»

## Решение по реализации

Клиент MVP — Flutter-приложение для iOS и Android. Приложение работает только с ролью **Клиент** и интегрируется с REST API из `01-analysis/api`.

Список и карточки заездов доступны в гостевом режиме без авторизации. OTP-вход требуется при попытке создать бронь, открыть «Мои записи», открыть «Профиль» или выполнить другую персональную операцию.

В MVP не реализуются интерфейс маршала, интерфейс владельца, админка, создание/редактирование расписания, онлайн-оплата, оценки маршалов, лояльность и авто-погода.

## Предварительный стек

Конкретные пакеты подтверждаются при bootstrap проекта. На уровне плана фиксируем роли библиотек:

- Flutter stable, Dart 3.
- Управление состоянием: согласованный reactive state management подход.
- Навигация: declarative router с поддержкой auth gate и return intent.
- HTTP-клиент: typed REST client с interceptor-слоем.
- Модели: immutable DTO/domain models + JSON serialization.
- Защищённое хранилище токенов: системное secure storage через согласованный Flutter-плагин.
- Локальный кэш для offline stale: согласованное key-value/document хранилище.
- Push-уведомления: системный push через согласованный Flutter-плагин.
- Карта: согласованный Flutter-плагин карт или текстовый fallback.
- Окружения/flavors: `--dart-define` или согласованный env-подход.
- Тесты: `flutter_test`, mock framework, HTTP mock adapter.
- Линтеры: `flutter_lints` или согласованный ruleset.

## Источники для разработки

- Экраны: `01-analysis/5-mobile-app-spec/*.md`.
- Общие логики: `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-*.md`.
- User stories: `01-analysis/2-requirements/user-stories.md`.
- Use cases: `01-analysis/2-requirements/use-cases.md`.
- API-контракт: `01-analysis/api/`.
- BE handoff: `02-development/BE_IMPLEMENTATION_PLAN.md`.

## Экраны MVP

| ID | Экран / bottom sheet | Фича |
|---|---|---|
| `SCR-001` | Регистрация / вход | OTP-авторизация |
| `SCR-002` | Список заездов | Точка входа в запись |
| `BS-001` | Фильтры | Фильтры записи |
| `SCR-003` | Карточка заезда | Детали заезда |
| `SCR-004` | Оформление записи | Форма бронирования |
| `BS-002` | Успех записи | Подтверждение брони |
| `SCR-005` | Мои записи | Список броней клиента |
| `SCR-006` | Детали брони | Детальная карточка брони |
| `BS-003` | Подтверждение отмены | Отмена брони |
| `BS-004` | Карта трассы | Карта и fallback |
| `SCR-007` | Профиль | Профиль клиента |

## API-операции

| Репозиторий | operationId | Endpoint |
|---|---|---|
| `AuthRepository` | `sendOtp` | `POST /auth/otp` |
| `AuthRepository` | `verifyOtp` | `POST /auth/verify` |
| `AuthRepository` | `refreshToken` | `POST /auth/refresh` |
| `SlotRepository` | `listSlots` | `GET /slots` без токена |
| `SlotRepository` | `getSlot` | `GET /slots/{slotId}` без токена |
| `MarshalRepository` | `listMarshals` | `GET /marshals` без токена |
| `BookingRepository` | `createBooking` | `POST /bookings` |
| `BookingRepository` | `listBookings` | `GET /bookings` |
| `BookingRepository` | `getBooking` | `GET /bookings/{bookingId}` |
| `BookingRepository` | `cancelBooking` | `POST /bookings/{bookingId}/cancel` |
| `ProfileRepository` | `getProfile` | `GET /profile` |
| `ProfileRepository` | `updateProfile` | `PATCH /profile` только имя |
| `ProfileRepository` | `sendPhoneChangeOtp` | `POST /profile/phone-change/otp` |
| `ProfileRepository` | `verifyPhoneChange` | `POST /profile/phone-change/verify` |
| `ProfileRepository` | `deleteAccount` | `DELETE /profile` |
| `ProfileRepository` | `registerPushToken` | `POST /profile/push-token` |

## Структура проекта

```text
client/
  pubspec.yaml
  analysis_options.yaml
  lib/
    main.dart
    app/
      apex_app.dart
      app_router.dart
      app_scope.dart
    core/
      application/
      config/
      error/
      network/
      storage/
      theme/
      time/
      ui/
    features/
      auth/
      slots/
      booking/
      profile/
      map/
      notifications/
  test/
  integration_test/
```

## Архитектурные правила

- Структура проекта строится по фичам.
- У каждой фичи есть `data`, `domain`, `application`, `presentation`.
- UI не вызывает HTTP-клиент напрямую.
- Presentation-слой использует согласованные state notifiers/controllers.
- Application-слой содержит use cases/controllers: `StartBookingIntent`, `SubmitBooking`, `ChangePhone`, `DeleteAccount`, `RegisterPushToken`, `OpenProtectedRoute`.
- Доменные правила — чистый Dart, покрытый unit tests.
- DTO изолированы в `data`.
- UI models собираются из domain models.
- Хранение токенов идёт только через `SessionRepository`.
- Ошибки API мапятся в типизированный `AppFailure`.
- Навигация не решает бизнес-логику напрямую: protected routes вызывают auth gate и возвращаются к сохранённому return intent.

## Session model

```dart
sealed class SessionState {}
class GuestSession extends SessionState {}
class AuthenticatedSession extends SessionState {
  final Client client;
}
```

Правила:

- Приложение стартует в `GuestSession`, если нет валидной сессии.
- `SCR-002`, `SCR-003`, `BS-001`, `BS-004` доступны гостю.
- `SCR-004`, `SCR-005`, `SCR-006`, `SCR-007` и все мутации требуют `AuthenticatedSession`.
- При попытке защищённого действия в гостевом режиме открывается `AuthFlow`, после успеха выполняется return intent.

## Базовые модели

```dart
enum TrackConfigType { novice, experienced }
enum GearChoice { own, rental }
enum SlotStatus { scheduled, cancelled }
enum BookingStatus { active, cancelled, lateCancel, cancelledByCenter, completed }

class Money {
  final int amount;
  final String currency; // RUB
}
```

Доменные сущности:

- `Client`;
- `TrackConfig`;
- `Marshal`;
- `Slot`;
- `Booking`;
- `BookingSlotSnapshot`;
- `MeetingPoint`;
- `Pagination`.

## Доменные правила

### `AvailabilityPolicy`

Правила:

- `maxSeats = min(slot.freeSeats, slot.trackConfig.capacityCap, 3)`.
- `seatGear.length` должен быть от 1 до `maxSeats`.
- `rentalCount <= slot.freeRentalGear`.
- Своя экипировка занимает место, но не расходует прокатную экипировку.

### `BookingPricePreviewCalculator`

Правила:

- Предварительный расчёт: `slot.price * seatsCount + slot.rentalPrice * rentalCount`.
- Экран созданной брони показывает `price_total` из API.
- `price_total` из API важнее локального preview.

### `CancellationPolicy`

Правила:

- `startAt - now >= 2h` означает раннюю отмену.
- `startAt - now < 2h` означает позднюю отмену.
- `now >= startAt` означает, что отмена недоступна.
- Клиентский preview информационный; финальный статус приходит из `cancelBooking`.

### `SlotFilterPolicy`

Правила:

- Группы фильтров: период дат, тип трассы, маршал, только доступные.
- Внутри multi-value группы используется OR.
- Между группами используется AND.
- Период по умолчанию: ближайшие 7 дней.

## Модель состояния

Использовать sealed state objects:

```dart
sealed class LoadState<T> {}
class Loading<T> extends LoadState<T> {}
class Content<T> extends LoadState<T> {
  final T data;
  final bool refreshing;
}
class Empty<T> extends LoadState<T> {}
class Failure<T> extends LoadState<T> {
  final UiError error;
}

enum ActionStatus { idle, submitting }
```

Правила экранов:

- Первичная загрузка экрана использует `Loading`.
- Pull-to-refresh оставляет content и выставляет `refreshing=true`.
- Мутации используют `ActionStatus.submitting`.
- Ошибки мутаций показываются через snackbar/dialog.
- `401` один раз запускает refresh token, затем logout.

## Навигация

```text
Splash
MainTabs
  BookingTab // «Запись»
    BookingSlotList // public
    FiltersSheet
    SlotDetails // public
    BookingForm // auth gate
    BookingSuccessSheet
    TrackMapSheet
  MyRecordsTab
    BookingList // auth gate
    BookingDetails
    CancelConfirmSheet
    TrackMapSheet
  ProfileTab
    Profile // auth gate
AuthFlow(returnIntent)
  PhoneStep
  OtpStep
  NameStep
```

Табы:

- `Запись`;
- `Мои записи`;
- `Профиль`.

Auth gate:

- Если гость открывает `BookingForm`, `MyRecordsTab` или `ProfileTab`, приложение открывает `AuthFlow(returnIntent)`.
- После успешного OTP приложение возвращается к исходному действию: выбранному слоту, форме бронирования, списку записей или профилю.
- Logout переводит сессию в `GuestSession` и оставляет пользователя в публичной части приложения.

## Сетевой слой

Реализовать:

- `HttpClient`;
- `PublicApiClient` или interceptor skip-list для public endpoints;
- `AuthorizedApiClient` для персональных endpoints и мутаций;
- `AuthInterceptor`;
- `RefreshTokenInterceptor`;
- `ErrorMapper`;
- `ApiConfig`.

Правила:

- Base URL берётся из окружения.
- Public endpoints `GET /slots`, `GET /slots/{slotId}`, `GET /marshals` не отправляют access token и работают в `GuestSession`.
- Все защищённые запросы содержат `Authorization: Bearer <access_token>`.
- Refresh token flow выполняется в single-flight режиме.
- Неуспешный refresh очищает secure storage.
- API `Error.code` сохраняется как `ApiFailure.code`.
- `createBooking` отправляет `Idempotency-Key`.
- `double_booking.details.booking_id` используется для перехода к существующей брони.

Поддерживаемые API error codes:

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

## Локальный кэш

Использовать согласованное локальное хранилище для read-only fallback:

- `slots_cache`;
- `bookings_cache`;
- `profile_cache`.

Правила:

- Кэш — только read-only fallback для уже загруженных данных.
- Кэшированные данные помечаются в UI как `Offline stale`.
- Мутации в offline заблокированы.
- Кэшированная доступность и цена не являются source of truth.

## План реализации фич

### FL-00. Каркас проекта

Сделать:

- Создать `client/`.
- Добавить `pubspec.yaml`.
- Добавить зависимости из стека.
- Добавить `analysis_options.yaml`.
- Добавить базовое приложение, router, theme, env config.

Готово когда:

- `flutter analyze` проходит.
- `flutter test` проходит.
- Приложение стартует и показывает splash/session check.

### FL-01. Тема и общие UI-компоненты

Сделать:

- Реализовать `ApexTheme`.
- Реализовать tokens:
  - colors;
  - typography;
  - spacing;
  - radius;
  - buttons;
  - text fields;
  - cards;
  - bottom sheets;
  - snackbars.
- Реализовать общие состояния экранов:
  - Loading;
  - Content;
  - Empty;
  - Error;
  - Offline stale.

Готово когда:

- Фичевые экраны используют общие UI primitives.
- В feature widgets нет hardcoded colors.
- Touch targets не меньше 44pt.

### FL-02. Авторизация `SCR-001`

Сделать:

- Поле телефона.
- Поле OTP.
- Поле имени для нового клиента.
- Вызов `sendOtp`.
- Вызов `verifyOtp`.
- Сохранение access/refresh tokens.
- Переход на `returnIntent` после успешного входа или на `SCR-002`, если вход запущен напрямую.
- Повторная отправка OTP после `retry_after`.
- Валидация имени и согласия/политики для нового пользователя.

Готово когда:

- Новый пользователь входит в приложение.
- Существующий пользователь входит в приложение.
- `invalid_code` показывает inline/snackbar ошибку.
- `rate_limit` показывает сообщение о повторной попытке.
- Вход из сценария бронирования возвращает пользователя к выбранному слоту/форме.

### FL-03. Сессия и refresh token

Сделать:

- Реализовать `SessionRepository`.
- Реализовать secure token storage.
- Реализовать проверку сессии при старте.
- Реализовать `refreshToken`.
- Реализовать auto logout после неуспешного refresh.
- Реализовать `GuestSession` и `AuthenticatedSession`.
- Реализовать auth gate для защищённых routes/actions.
- Реализовать return intent после OTP.

Готово когда:

- Без refresh token приложение открывает публичный список заездов в `GuestSession`.
- С валидным refresh token приложение открывает main tabs.
- `401` один раз запускает refresh.
- Неуспешный refresh очищает сессию.
- Защищённые действия из guest mode открывают OTP и возвращаются к исходному действию.

### FL-04. Публичная запись: список заездов `SCR-002`

Сделать:

- Загрузить `GET /slots` без access token.
- Применить период по умолчанию: ближайшие 7 дней.
- Отрисовать карточки заездов для выбора записи.
- Показать disabled-состояние для заполненных и отменённых заездов.
- Сохранить загруженные slots в локальный read-only cache.
- Показать offline stale из кэша.

Готово когда:

- Работают состояния Loading, Content, Empty, Error, Offline stale.
- Карточки заездов отсортированы по `start_at`.
- Заполненные и отменённые заезды не открывают CTA записи.
- Экран работает без авторизации.

### FL-05. Фильтры `BS-001`

Сделать:

- Загрузить `GET /marshals`.
- Реализовать фильтры:
  - период дат;
  - тип трассы;
  - маршал;
  - только доступные.
- Реализовать применение и сброс фильтров.

Готово когда:

- Применённые фильтры обновляют query для `GET /slots`.
- Сброс возвращает период по умолчанию: ближайшие 7 дней.
- Пустой результат фильтра показывает корректное empty state.

### FL-06. Карточка заезда `SCR-003`

Сделать:

- Загрузить `GET /slots/{slotId}`.
- Показать конфигурацию, маршала, цену, места, прокатную экипировку, точку сбора.
- Показать preview карты.
- Открывать `BS-004`.
- Открывать `SCR-004` только для доступного scheduled slot; при guest mode сначала auth gate.

Готово когда:

- Детали перезагружаются перед оформлением брони.
- Отменённый слот показывает disabled CTA.
- Текстовый fallback карты работает без map key.
- Карточка работает без авторизации.

### FL-07. Форма бронирования `SCR-004`

Сделать:

- Если пользователь в `GuestSession`, сначала выполнить auth gate и вернуть к форме.
- Показать сводку заезда.
- Дать выбрать 1-3 места.
- Дать выбрать свою/прокатную экипировку на каждое место.
- Валидировать доступность через `AvailabilityPolicy`.
- Показать предварительный расчёт цены.
- Отправить `POST /bookings` с `slot_id`, `seat_gear[]`, `Idempotency-Key`.

Готово когда:

- Пользователь не может выбрать больше доступного максимума мест.
- Пользователь не может выбрать больше прокатной экипировки, чем доступно.
- `slot_full` обновляет UI серверными значениями.
- `double_booking` предлагает перейти к существующей брони.
- `slot_started` блокирует запись и обновляет состояние слота.
- Успех открывает `BS-002`.

### FL-08. Успех записи `BS-002`

Сделать:

- Показать сводку брони из API `Booking`.
- Показать `price_total`.
- Показать точку сбора.
- Добавить действия:
  - перейти в `Мои записи`;
  - перейти в `Запись`.
- Запросить permission на push после первой успешной брони.

Готово когда:

- Bottom sheet успеха показывает значения брони из API.
- Действия навигации работают.
- Push permission не блокирует успешное оформление брони.

### FL-09. Мои записи `SCR-005`

Сделать:

- Загрузить `GET /bookings`.
- Реализовать пагинацию с `limit=20`.
- Сгруппировать брони:
  - предстоящие;
  - прошедшие;
  - отменённые.
- Сохранить загруженные bookings в локальный read-only cache.
- Заменить live-slot предположения на отображение `BookingSlotSnapshot`.

Готово когда:

- Empty state работает.
- Offline stale показывает кэшированные брони.
- `cancelled_by_center` видна в списке.
- Неавторизованный пользователь попадает в auth gate, затем возвращается к списку.

### FL-10. Детали брони `SCR-006`

Сделать:

- Загрузить `GET /bookings/{bookingId}`.
- Показать статус, snapshot данных заезда, маршала, экипировку, цену, точку сбора, карту.
- Показывать кнопку отмены только для активной будущей брони.
- Показать причину отмены центром для `cancelled_by_center`.

Готово когда:

- Детали показывают все поля из mobile spec.
- Видимость кнопки отмены следует статусу и времени.
- Map sheet открывается из деталей.
- Чужая/недоступная бронь через `forbidden`/`not_found` показывает безопасный error state.

### FL-11. Подтверждение отмены `BS-003`

Сделать:

- Показать подтверждение отмены всей брони.
- Показать раннюю/позднюю отмену через `CancellationPolicy`.
- Отправить `POST /bookings/{bookingId}/cancel`.
- Заменить локальные детали ответом API.

Готово когда:

- Ровно 2 часа до старта показываются как ранняя отмена.
- Offline cancel заблокирован.
- `already_cancelled` показывает snackbar и обновляет детали.

### FL-12. Карта трассы `BS-004`

Сделать:

- Реализовать preview/sheet через согласованный Flutter-плагин карт.
- Показать pin точки сбора.
- Нарисовать геометрию трассы, если она есть.
- Показать текстовый fallback, если карта не загрузилась или geometry отсутствует.
- Добавить открытие внешней карты.

Готово когда:

- Карта работает с валидной конфигурацией.
- Текстовый fallback работает без map key.
- Ошибка карты не блокирует запись.

### FL-13. Профиль `SCR-007`

Сделать:

- Загрузить `GET /profile`.
- Редактировать имя через `PATCH /profile`.
- Реализовать смену телефона через `sendPhoneChangeOtp` и `verifyPhoneChange`.
- Зарегистрировать push token через `POST /profile/push-token`.
- Logout очищает secure storage.
- Удаление аккаунта идёт через `DELETE /profile`, затем очищает secure storage.

Готово когда:

- Профиль загружается, изменения сохраняются.
- `PATCH /profile` не отправляет phone.
- Смена телефона обрабатывает `invalid_code`, `rate_limit`, `phone_already_used`.
- Logout очищает сессию и возвращает в публичную часть приложения.
- Удаление аккаунта возвращает в auth flow после успешного ответа API.
- Push token registration повторяется при следующей загрузке профиля/сессии после ошибки.

### FL-14. Push `LOGIC-007`

Сделать:

- Запросить system permission после первой успешной брони.
- Получить системный push token через согласованный Flutter-плагин.
- Отправить token в `registerPushToken`.
- Сохранить локальный флаг, что permission уже запрашивался.

Готово когда:

- Denied permission не ломает приложение.
- Granted permission регистрирует token.
- Token refresh обновляет backend.
- Push об отмене центром открывает детали брони.

### FL-15. Тесты и smoke flow

Сделать:

- Unit tests для policies:
  - availability;
  - price preview;
  - cancellation;
  - filters;
  - grouping.
- Тесты репозиториев с HTTP mock adapter.
- Widget tests для auth, booking form, cancel sheet.
- Ручной smoke flow.

Готово когда:

- `flutter analyze` проходит.
- `flutter test` проходит.
- Smoke flow проходит:
  - auth;
  - `Запись`;
  - filters;
  - details;
  - booking;
  - success;
  - `Мои записи`;
  - cancel;
  - profile logout.

## Порядок реализации

1. `FL-00` Каркас проекта.
2. `FL-01` Тема и общие UI-компоненты.
3. `FL-04` Публичная запись: список заездов.
4. `FL-05` Фильтры.
5. `FL-06` Карточка заезда.
6. `FL-03` Сессия, refresh token и auth gate.
7. `FL-02` Авторизация.
8. `FL-07` Форма бронирования.
9. `FL-08` Успех записи.
10. `FL-09` Мои записи.
11. `FL-10` Детали брони.
12. `FL-11` Подтверждение отмены.
13. `FL-12` Карта трассы.
14. `FL-13` Профиль и смена телефона.
15. `FL-14` Push.
16. `FL-15` Тесты и smoke flow.

## Открытые вопросы

1. Design tokens пока описаны только на уровне design brief. Перед финальной UI-реализацией нужен UI-kit export или таблица tokens.
2. Карта может стартовать с текстового fallback + открытием внешней карты, если выбранный Flutter-плагин карт не готов.
3. Push reminder timings `[24, 2]` остаются предположением; клиент не должен считать их финальной продуктовой правдой без API/config.
4. Глубина offline stale cache требует решения: только memory/session cache для MVP или persistent cache между запусками.
