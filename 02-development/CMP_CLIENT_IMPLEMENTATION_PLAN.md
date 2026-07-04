# План реализации Flutter-клиента для «Апекс»

## Контекст анализа

Документ проектирует клиентское мобильное приложение «Апекс» для iOS и Android на Flutter. Основа: clean architecture, feature-first структура, контрактная интеграция с BE и OpenAPI из `01-analysis/api`.

Источники:

- `01-analysis/5-mobile-app-spec/README.md` и экранные ТЗ `SCR-*`, `BS-*`.
- Переиспользуемые логики `01-analysis/5-mobile-app-spec/09_Логики/LOGIC-*`.
- API-контракты `01-analysis/api/{auth,slots,bookings,profile,marshals}/`.
- `01-analysis/2-requirements/user-stories.md`.
- `01-analysis/2-requirements/use-cases.md`.
- `02-development/BE_IMPLEMENTATION_PLAN.md`.

## Выводы по требованиям

MVP-клиент покрывает только роль клиента:

- `SCR-001` регистрация / вход по телефону и OTP.
- `SCR-002` список заездов.
- `BS-001` фильтры.
- `SCR-003` карточка заезда.
- `SCR-004` оформление записи.
- `BS-002` успех записи и запрос push-разрешения.
- `SCR-005` мои записи.
- `SCR-006` детали брони и отмена.
- `BS-003` подтверждение отмены.
- `BS-004` карта трассы.
- `SCR-007` профиль, выход, операции профиля.

Клиент не должен реализовывать marshal/admin/owner UI, schedule CRUD, создание/редактирование слотов, онлайн-оплату, оценки маршалов, loyalty, no-show и auto-weather cancellation.

Сквозные логики, которые должны стать отдельными domain/application сервисами или pure-функциями:

- `LOGIC-001` OTP-авторизация и сессия.
- `LOGIC-002` доступность: `min(free_seats, track_config.capacity_cap, 3)` плюс проверка `free_rental_gear`.
- `LOGIC-003` цена: серверный `price_total` является источником истины для созданной брони; локальный расчёт допускается только как preview.
- `LOGIC-004` отмена: `>= 2h` ранняя, `< 2h` поздняя, после старта отмена недоступна.
- `LOGIC-005` фильтры слотов: OR внутри группы, AND между группами.
- `LOGIC-006` карта: Flutter-плагин карт или fallback; обязательный текстовый fallback.
- `LOGIC-007` push-разрешение после первой успешной брони.
- `LOGIC-008` Loading / Content / Empty / Error / Offline stale.

## Выводы по текущему BE/API

Клиентские endpoints:

| Домен | operationId | Метод |
|---|---|---|
| Auth | `sendOtp` | `POST /auth/otp` |
| Auth | `verifyOtp` | `POST /auth/verify` |
| Auth | `refreshToken` | `POST /auth/refresh` |
| Slots | `listSlots` | `GET /slots` |
| Slots | `getSlot` | `GET /slots/{slotId}` |
| Marshals | `listMarshals` | `GET /marshals` |
| Bookings | `createBooking` | `POST /bookings` |
| Bookings | `listBookings` | `GET /bookings` |
| Bookings | `getBooking` | `GET /bookings/{bookingId}` |
| Bookings | `cancelBooking` | `POST /bookings/{bookingId}/cancel` |
| Profile | `getProfile` | `GET /profile` |
| Profile | `updateProfile` | `PATCH /profile` |
| Profile | `deleteAccount` | `DELETE /profile` |
| Profile | `registerPushToken` | `POST /profile/push-token` |

BE важные особенности для клиента:

- Bearer access token хранится в secure storage.
- При `401` клиент централизованно пробует refresh; если refresh неуспешен, очищает сессию и открывает auth flow.
- `createBooking` требует `Idempotency-Key`; клиент генерирует UUID на одну попытку отправки формы и держит ключ для retry того же payload.
- `createBooking` отправляет `slot_id` и `seat_gear[]`; `seats_count` вычисляет сервер.
- Ошибки приходят в формате `{ code, message, details? }`; action errors показываются snackbar/dialog без разрушения текущего content state.
- `slot_full` может содержать актуальные значения мест/проката в `details`; UI должен обновлять форму и подсказывать уменьшить места/прокат.
- `Slot.status = cancelled` означает отмену заезда центром; `Booking.status = cancelled` означает раннюю отмену клиентом.

## Целевая структура проекта

Создать клиент под `client/`:

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
      config/
      error/
      network/
      storage/
      time/
      ui/
      theme/
      utils/
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

Рекомендуемый стек:

- Flutter stable + Dart 3.
- State management: Riverpod или Bloc. Для MVP предпочтителен Riverpod с immutable state и use case слоями.
- Navigation: `go_router`.
- Network: `dio` + interceptors для Bearer/refresh.
- Serialization: `json_serializable` + `freezed`.
- Secure storage: `flutter_secure_storage`.
- Push: FCM/APNs через `firebase_messaging` или выбранный командой плагин.
- Maps: согласованный Flutter-плагин карт; fallback обязателен.
- Local cache: lightweight repository cache или Drift/Hive только если offline stale нужно переживать рестарт приложения.
- Tests: unit/widget/integration tests.

## Чистая архитектура

Зависимости направлены внутрь:

```text
presentation -> application/usecase -> domain
data -> domain interfaces
platform adapters -> shared interfaces
```

Слои:

- `domain`: сущности, value objects, pure rules, repository interfaces.
- `application`: use cases, session orchestration, state reducers/controllers.
- `data`: API clients, DTO, mappers, repositories, pagination, idempotency persistence.
- `presentation`: screens, widgets, state controllers, navigation.
- `platform`: secure storage, push permission, maps, external links, clock.

Пакеты:

```text
core
  config
  error
  network
  storage
  time
  ui
  theme
features
  auth
  slots
  booking
  profile
  map
  notifications
```

## Domain model

Основные модели:

```dart
class Client {
  final String id;
  final String name;
  final String phone;
}

class TrackConfig {
  final String id;
  final String name;
  final String? description;
  final TrackConfigType type;
  final int capacityCap;
  final int? durationMin;
  final List<GeoPoint>? geometry;
}

class Slot {
  final String id;
  final TrackConfig trackConfig;
  final Marshal marshal;
  final DateTime startAt;
  final int totalSeats;
  final int freeSeats;
  final int freeRentalGear;
  final Money price;
  final Money rentalPrice;
  final MeetingPoint meetingPoint;
  final SlotStatus status;
  final String? cancelReason;
}

class Booking {
  final String id;
  final Slot slot;
  final int seatsCount;
  final int rentalCount;
  final List<GearChoice> seatGear;
  final Money priceTotal;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
}
```

Pure services:

- `AvailabilityPolicy`: `maxSeatsForBooking(slot)`, `canRentGear(seatGear, slot)`.
- `BookingPricePreviewCalculator`: `price * seats + rentalPrice * rental`.
- `CancellationPolicy`: `early`, `late`, `unavailableAfterStart`.
- `SlotFilterPolicy`: query builder and applied filter count.
- `BookingGroupingPolicy`: upcoming/past/cancelled derived from `slot.startAt` and booking status.

## State стандарт

Каждый экран получает:

- `State`: immutable UI state.
- `Intent/Action`: пользовательские действия.
- `Effect`: одноразовые события навигации/snackbar/system dialog.
- `Controller/Notifier`: use case calls, reducer-style state updates.

Базовые типы:

```dart
sealed class Loadable<T> {
  const Loadable();
}

final class Loading<T> extends Loadable<T> {}
final class Content<T> extends Loadable<T> {
  final T value;
  final bool refreshing;
}
final class Empty<T> extends Loadable<T> {}
final class Failure<T> extends Loadable<T> {
  final UiError error;
}

enum ActionStatus { idle, submitting }
```

Правила:

- Первичная загрузка: `Loading -> Content|Empty|Failure`.
- Pull-to-refresh: контент сохраняется, `refreshing=true`; ошибка только snackbar.
- Action submit: отдельный `ActionStatus.submitting`, повторный tap блокируется.
- 4xx с `message`: snackbar/dialog, а не full-screen error, если это action.
- `401`: централизованно refresh или очистка сессии и переход в auth flow.

## Навигация

Root graph:

```text
Root
  SplashSessionCheck
  AuthFlow
    PhoneStep
    OtpStep
    NameStep
  MainTabs
    SlotsStack
      SlotList
      SlotDetails
      BookingForm
    BookingsStack
      BookingList
      BookingDetails
    ProfileStack
      Profile
```

Bottom sheets:

- `FiltersSheet` over `SlotList`.
- `BookingSuccessSheet` after successful `createBooking`.
- `CancelConfirmSheet` over `BookingDetails`.
- `TrackMapSheet` over `SlotDetails` or `BookingDetails`.

## Data layer и API

Репозитории:

- `AuthRepository`: `sendOtp`, `verifyOtp`, `refreshToken`.
- `ProfileRepository`: `getProfile`, `updateProfile`, `deleteAccount`, `registerPushToken`.
- `SlotRepository`: `listSlots`, `getSlot`.
- `MarshalRepository`: `listMarshals`.
- `BookingRepository`: `createBooking`, `listBookings`, `getBooking`, `cancelBooking`.
- `SessionRepository`: token read/write/clear, auth state stream.

Dio setup:

- JSON serialization with snake_case mapping.
- Base URL from flavor/env config.
- Auth interceptor injecting `Authorization: Bearer`.
- Refresh interceptor with single-flight refresh to avoid parallel refresh storms.
- Response mapper from API `Error` into typed `ApiFailure`.
- Timeout and network-unavailable mapping.

Typed failures:

```dart
sealed class AppFailure {}
final class UnauthorizedFailure extends AppFailure {}
final class ApiFailure extends AppFailure {
  final String code;
  final String message;
  final Map<String, Object?>? details;
}
final class NetworkUnavailableFailure extends AppFailure {}
final class TimeoutFailure extends AppFailure {}
final class UnknownFailure extends AppFailure {}
```

Idempotency:

- `CreateBookingUseCase` generates UUID `Idempotency-Key` per form submission.
- Same key is reused for retry of identical `slot_id` and `seat_gear[]`.
- If payload changes, old key is discarded.
- On idempotency conflict, show server `message`, regenerate key only after user intentionally retries with a new submission.

## Feature design

### Auth: `SCR-001`, `LOGIC-001`

State:

- step: phone / otp / name.
- phone, code, name.
- resend timer.
- actionStatus.

Use cases:

- `SendOtpUseCase`.
- `VerifyOtpUseCase`.
- `RefreshTokenUseCase`.
- `ObserveSessionUseCase`.

Acceptance focus:

- Phone validation before request.
- OTP field handles invalid code and rate limit.
- `name` is sent for new client.
- Successful auth opens `SCR-002`.

### Slots catalog: `SCR-002`, `BS-001`, `SCR-003`

State:

- `Loadable<List<SlotSummary>>`.
- applied filters and draft filters.
- marshal dictionary load state.
- active filter count.

Use cases:

- `LoadSlotsUseCase`.
- `RefreshSlotsUseCase`.
- `LoadMarshalsUseCase`.
- `BuildSlotQueryUseCase`.
- `LoadSlotDetailsUseCase`.

Client rules:

- Default period is nearest 7 days if no user filter is applied.
- Default `only_available=false`, unless UI explicitly applies «только свободные».
- Slots without places are shown disabled/marked if returned by API.
- Slot details reload with `getSlot` to avoid stale availability before booking.

### Booking form: `SCR-004`, `BS-002`

State:

- slot content.
- `seatGear` list length 1..3 and not above available max.
- derived `seatsCount` and `rentalCount`.
- computed total price preview.
- actionStatus.

Use cases:

- `CreateBookingUseCase`.
- `CalculateAvailabilityUseCase`.
- `CalculateBookingPricePreviewUseCase`.
- `RequestPushPermissionAfterBookingUseCase`.

Client rules:

- Do not hardcode track caps or rental gear count.
- Own gear consumes group seat, not rental gear.
- On `slot_full`, use `details` to update max and show contextual message.
- On success, show `BS-002`, invalidate slots and bookings caches.

### My bookings: `SCR-005`, `SCR-006`, `BS-003`

State:

- bookings list with pagination.
- upcoming / past / cancelled groups.
- cancel availability derived by `now < slot.startAt`.
- cancel type preview by `CancellationPolicy`.

Use cases:

- `LoadBookingsUseCase`.
- `LoadBookingDetailsUseCase`.
- `CancelBookingUseCase`.

Client rules:

- Exactly 2 hours before start is early cancellation.
- After cancel, replace details with server response and invalidate bookings list/slots.
- Repeated cancel errors (`already_cancelled`) show snackbar and refresh details.
- `cancelled_by_center` shows reason and disables repeated booking on the cancelled slot.

### Profile: `SCR-007`

State:

- profile loadable.
- edit name/phone state.
- delete account confirmation.
- push permission state.

Use cases:

- `LoadProfileUseCase`.
- `UpdateProfileUseCase`.
- `LogoutUseCase`.
- `DeleteAccountUseCase`.
- `RegisterPushTokenUseCase`.

Client rules:

- Logout clears secure storage locally.
- Delete account waits for API success, then clears secure storage.
- Phone change requires OTP if backend enforces this flow.

### Maps: `LOGIC-006`, `BS-004`

Shared contract:

```dart
abstract interface class MapLauncher {
  Future<void> openExternalMap(MeetingPoint point);
}
```

Rules:

- Map preview and map sheet must not call Apex REST API directly.
- Inputs come from `getSlot` or `getBooking`.
- If `trackConfig.geometry == null`, show pin + text and treat as Content without line.
- If map SDK/API/key fails, show text fallback + action to open external maps.
- Map API key must come from build/env config, never hardcoded in code.

## Theme and design tokens

Цель: дизайн-бриф и будущий Figma/UI-kit становятся источником visual tokens, Flutter theme - source of implementation truth.

Required extraction after design access:

- Color styles/variables: brand, background, surface, text, border, success, warning, error, info, overlay.
- Typography: font family, sizes, line heights, weights for display/title/body/label.
- Spacing scale.
- Radius scale.
- Component anatomy: buttons, text fields, chips, cards, bottom sheets, tabs, snackbars, skeletons.
- Light/dark modes if defined.

Flutter implementation:

```text
core/theme/
  apex_theme.dart
  apex_colors.dart
  apex_typography.dart
  apex_spacing.dart
  apex_shapes.dart
  apex_components.dart
```

Theme acceptance:

- No hardcoded colors in feature screens.
- No hardcoded typography except inside theme.
- Components read tokens from `ApexTheme`.
- Contrast for primary text/buttons meets WCAG AA and `NFR-1`.
- All screen states from `LOGIC-008` have tokenized skeleton, empty, error and snackbar visuals.

## Platform specifics

Android:

- Secure token in `flutter_secure_storage` backed by Android Keystore.
- Push permission for Android 13+.
- External map handoff through intent/browser fallback.

iOS:

- Secure token in Keychain via `flutter_secure_storage`.
- Push permission through APNs/FCM.
- External map handoff through URL schemes/universal links.

## Testing strategy

Unit tests:

- `LOGIC-002` availability boundaries.
- `LOGIC-003` price preview calculation.
- `LOGIC-004` cancellation boundary: `2h+1s`, `2h`, `1h59m59s`, after start.
- slot filter query builder.
- booking grouping upcoming/past/cancelled.
- state controllers for every screen.
- API error mapping.

Data tests:

- Dio/mock adapter success/error for every operationId.
- `401` refresh and session clear.
- create booking idempotency key reuse/discard behavior.
- snake_case DTO serialization.

Widget tests:

- StateContainer Loading/Empty/Error/Offline stale.
- Auth flow validation.
- Booking form validation.
- Cancel confirmation.

E2E/manual smoke:

- Login new user -> name -> slot list -> slot details -> booking -> success -> my bookings -> cancel -> profile logout.
- Repeat booking network retry with same idempotency key.
- Map fallback when geometry/key is missing.

## Implementation roadmap

- [ ] `FL-00` Create `client/` Flutter skeleton with flavors/env config.
- [ ] `FL-01` Add dependency catalog, lints, formatting and test tasks.
- [ ] `FL-02` Implement core architecture: state base, DI, config, clock, error model, logging.
- [ ] `FL-03` Implement theme skeleton and token import format.
- [ ] `FL-04` Finalize `ApexTheme` after design token extraction.
- [ ] `FL-05` Implement network layer and DTOs aligned with OpenAPI.
- [ ] `FL-06` Implement secure/session storage.
- [ ] `FL-07` Implement Auth flow `SCR-001`.
- [ ] `FL-08` Implement main navigation and tabs.
- [ ] `FL-09` Implement slots list, filters and marshals dictionary `SCR-002`/`BS-001`.
- [ ] `FL-10` Implement slot card and map preview fallback `SCR-003`.
- [ ] `FL-11` Implement booking form and success sheet `SCR-004`/`BS-002`.
- [ ] `FL-12` Implement bookings list/details/cancel `SCR-005`/`SCR-006`/`BS-003`.
- [ ] `FL-13` Implement track map sheet `BS-004`.
- [ ] `FL-14` Implement profile view, edit data, logout, delete account `SCR-007`.
- [ ] `FL-15` Implement push permission and token registration `LOGIC-007`.
- [ ] `FL-16` Add unit/data/widget tests for core flows.
- [ ] `FL-17` Run integration smoke against local BE.
- [ ] `FL-18` Polish accessibility and visual parity with design brief/Figma.

## Open questions and gaps

1. Figma/design tokens are not yet extracted. Need access/tooling before final UI implementation.
2. Concrete map plugin is not selected. MVP can start with text fallback + external map handoff.
3. Push reminder timings `[24, 2]` are assumptions; client must not hardcode them as final product truth without API/config.
4. Phone change flow needs final BE decision: same `updateProfile` with OTP or separate confirmation flow.
5. Offline stale cache depth needs decision: memory-only for MVP session or persistent cache across app restarts.
