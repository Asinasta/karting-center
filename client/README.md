# Apex Flutter Client

Flutter MVP-клиент для картинг-центра «Апекс».

## Setup

Если папка `client/` уже создана из репозитория, сначала подтяни зависимости:

```powershell
cd C:\Users\azari\karting-center\client
.\check.ps1
```

Или по шагам: `flutter pub get`, `flutter analyze`, `flutter test`.

Нужен **Dart 3.9+** (`flutter upgrade`, если `flutter --version` показывает меньше).

Если Flutter попросит платформенные файлы (`android/`, `web/`, `.metadata`), сгенерируй их внутри `client/`:

```powershell
flutter create . --project-name apex_client --org ru.apex
flutter pub get
```

После `flutter create .` проверь, что `pubspec.yaml` сохранил зависимости проекта.

## Backend

Перед запуском клиента подними FastAPI:

```powershell
cd C:\Users\azari\karting-center\backend
.\.venv\Scripts\python.exe manage.py run
```

## Run

По умолчанию клиент сам выбирает URL API:

- **Web / Windows / macOS / Linux** → `http://localhost:8080`
- **Android emulator** → `http://10.0.2.2:8080`

```powershell
flutter run -d chrome
```

Переопределить вручную:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

## Текущее состояние

Реализованы FL-00..FL-13 и большая часть FL-14/FL-15:

- `FL-00/01`: каркас, router c auth gate, тема и общие UI-состояния.
- `FL-02/03`: OTP-вход (SCR-001), сессия, secure storage, single-flight refresh, return intent.
- `FL-04/05/06`: публичный список заездов (SCR-002), фильтры (BS-001), карточка заезда (SCR-003).
- `FL-07/08`: форма бронирования (SCR-004) с Idempotency-Key и превью цены, успех записи (BS-002).
- `FL-09/10/11`: мои записи (SCR-005), детали брони (SCR-006), отмена (BS-003) с правилом 2 часов.
- `FL-12`: карта трассы (BS-004) — отрисовка geometry + текстовый fallback + внешняя карта.
- `FL-13`: профиль (SCR-007) — имя, смена телефона по OTP, logout, удаление аккаунта.
- `FL-14`: заглушка push-сервиса (permission-флаг + registerPushToken); плагин push не выбран.
- `FL-15`: unit-тесты policies и репозиториев с MockClient (`flutter test`).

Dev OTP-код бэкенда (fixtures): `0000`.
