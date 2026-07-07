# BUG-004. Проверка сессии на splash вызывала `setState during build` у роутера

## Симптом

При старте приложения (web) в консоли — `DartError: setState() or markNeedsBuild() called during build`. Стек: `SplashScreen.initState` → `SessionController.checkSession()` → `notifyListeners()` → `GoRouter` / `Router` пытается перестроиться во время первого build. Навигация после splash могла работать нестабильно.

## Требования

- `02-development/CMP_CLIENT_IMPLEMENTATION_PLAN.md` — **FL-03**: проверка сессии при старте, `GuestSession` / `AuthenticatedSession`, auth gate.
- `01-analysis/5-mobile-app-spec/SCR-002-slot-list.md` — публичный каталог для гостя после старта.
- Связан с FL-03 (сессия при старте, `refreshListenable: session`, `checkSession()` на splash).

## Причина

`SplashScreen` вызывал `checkSession()` синхронно из `initState`. `checkSession()` сразу вызывал `_setState(CheckingSession())` → `notifyListeners()`. `GoRouter` подписан на `SessionController` как `refreshListenable` и пытался пересчитать redirect до завершения первого кадра. Повторный `CheckingSession` при уже установленном начальном состоянии давал лишний `notifyListeners()`.

## Исправление

- `client/lib/features/session/presentation/splash_screen.dart` — `checkSession()` перенесён в `WidgetsBinding.instance.addPostFrameCallback`.
- `client/lib/features/session/session_controller.dart` — `_setState` не вызывает `notifyListeners()`, если состояние не изменилось.
- `client/test/widgets/splash_screen_test.dart` — автотест: старт с `GoRouter` + `refreshListenable` без ошибки build.

## Промпты

```
Uncaught (in promise) DartError: setState() or markNeedsBuild() called during build.
...
at session_controller.dart:87 notifyListeners
at session_controller.dart:31 checkSession
at splash_screen.dart:26 initState
```

## Проверка вручную

1. `cd client && flutter test test/widgets/splash_screen_test.dart` — тест проходит.
2. `flutter run -d chrome`, обновить страницу (F5).
3. В консоли нет `setState() called during build`.
4. После splash — переход на `/slots` (гость) или восстановление сессии (если есть refresh token в secure storage).
5. Повторить сценарии FL-03: auth gate, return intent после OTP.

Автотест: `client/test/widgets/splash_screen_test.dart` — `SplashScreen does not notify router during first build`.
