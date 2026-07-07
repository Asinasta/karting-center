# BUG-003. Splash не проверял сессию, защищённые разделы без auth gate

## Симптом

1. При старте приложение всегда переходило на `/slots`, даже если в secure storage был refresh token — сессия не восстанавливалась (FL-03).
2. Вкладки «Мои записи» и «Профиль» открывались гостю без редиректа на OTP-вход.
3. «Записаться» на карточке заезда не перенаправляло гостя на SCR-001 перед формой бронирования.

## Требования

- `02-development/CMP_CLIENT_IMPLEMENTATION_PLAN.md` — FL-03: `SessionRepository`, refresh, auth gate, return intent.
- `01-analysis/5-mobile-app-spec/SCR-002-slot-list.md` — вход запрашивается при записи и персональных разделах.
- `01-analysis/5-mobile-app-spec/SCR-001-registration.md` — return intent после OTP из сценария записи.

## Причина

`SessionController.checkSession()` содержал заглушку с `Future.delayed` и всегда устанавливал `GuestSession`. Роутер не имел `redirect` для protected paths. `SplashScreen` безусловно вызывал `context.go('/slots')`.

## Исправление

- `client/lib/features/session/data/session_repository.dart` — secure storage, single-flight refresh, очистка при неуспехе.
- `client/lib/features/session/session_controller.dart` — `restore()` refresh token, загрузка профиля, `signIn` / `logout`.
- `client/lib/app/app_router.dart` — `refreshListenable: session`, redirect на `/auth?return=...` для `/bookings*`, `/profile`, `/slots/:id/book`.
- `client/lib/features/session/presentation/splash_screen.dart` — только UI; навигация через redirect роутера после `checkSession()`.

## Промпты

```
FL-03: сессия, refresh token и auth gate
FL-02: авторизация
После успешного OTP приложение возвращается к return intent.
```


## Проверка вручную

1. Запустить приложение без токенов → список заездов (гость).
2. «Записаться» на доступном слоте → экран входа с `return` в URL.
3. OTP (`0000`) → возврат на форму бронирования.
4. Вкладка «Мои записи» без входа → auth gate → после входа список броней.
5. Logout в профиле → снова гостевой режим, публичный список доступен.

Автотест: `client/test/data/repositories_test.dart` — `401 triggers one refresh and one retry`.

## Коммит

- исправление: `e8ef923` — feat(task-03): backend API and Flutter client MVP
- документ: `3e782cb` — docs(bug-003): missing session check and auth gate
