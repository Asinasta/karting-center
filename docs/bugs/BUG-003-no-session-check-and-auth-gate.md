# BUG-003. Splash не проверял сессию, защищённые разделы без auth gate

## Симптом

1. При старте приложение всегда переходило на `/slots`, даже если в secure storage был refresh token — сессия не восстанавливалась (FL-03).
2. Вкладки «Мои записи» и «Профиль» показывали заглушки вместо OTP-входа.
3. «Записаться» на карточке заезда не перенаправляло гостя на SCR-001 перед формой бронирования.

## Требования

- `02-development/CMP_CLIENT_IMPLEMENTATION_PLAN.md` — FL-03: `SessionRepository`, refresh, auth gate, return intent.
- `01-analysis/5-mobile-app-spec/SCR-002-slot-list.md` — вход запрашивается при записи и персональных разделах.
- `01-analysis/5-mobile-app-spec/SCR-001-registration.md` — return intent после OTP из сценария записи.

## Причина

`SessionController.checkSession()` содержал заглушку с `Future.delayed` и всегда устанавливал `GuestSession`. Роутер не имел `redirect` для protected paths. `SplashScreen` безусловно вызывал `context.go('/slots')`.

## Исправление

- `SessionRepository` — secure storage, single-flight refresh, очистка при неуспехе.
- `SessionController` — `restore()` refresh token, загрузка профиля, `signIn` / `logout`.
- `app_router.dart` — `refreshListenable: session`, redirect на `/auth?return=...` для `/bookings*`, `/profile`, `/slots/:id/book`.
- `SplashScreen` — только UI; навигация через redirect роутера после `checkSession()`.

## Промпты

```
FL-03: сессия, refresh token и auth gate
FL-02: авторизация
После успешного OTP приложение возвращается к return intent.
```

Полный контекст: `docs/prompts/chat-06-flutter-client-development.txt`.

## Проверка вручную

1. Запустить приложение без токенов → список заездов (гость).
2. «Записаться» на доступном слоте → экран входа с `return` в URL.
3. OTP (`0000`) → возврат на форму бронирования.
4. Вкладка «Мои записи» без входа → auth gate → после входа список броней.
5. Logout в профиле → снова гостевой режим, публичный список доступен.

Автотест: `client/test/data/repositories_test.dart` — `401 triggers one refresh and one retry`.

## Коммит

`fix(client): session check and auth gate for protected routes (BUG-003)`
