# Apex Flutter Client

Flutter MVP-клиент для картинг-центра «Апекс».

## Setup

```bash
cd client
flutter pub get
flutter analyze
flutter test
```

Если Flutter попросит платформенные файлы:

```bash
flutter create . --project-name apex_client --org ru.apex
flutter pub get
```

## Backend

Перед запуском клиента подними FastAPI — см. [`../RUN_LOCAL.md`](../RUN_LOCAL.md) и [`../backend/README.md`](../backend/README.md).

## Run

По умолчанию клиент выбирает URL API:

- **Web / Windows / macOS / Linux** → `http://localhost:8080`
- **Android emulator** → `http://10.0.2.2:8080`

```bash
flutter run -d chrome
```

Переопределить:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

## Текущее состояние

Реализованы FL-00..FL-13 и частично FL-14/FL-15:

- `FL-00/01`: каркас, router c auth gate, тема и общие UI-состояния.
- `FL-02/03`: OTP-вход (SCR-001), сессия, secure storage, single-flight refresh, return intent.
- `FL-04/05/06`: публичный список заездов (SCR-002), фильтры (BS-001), карточка заезда (SCR-003).
- `FL-07/08`: форма бронирования (SCR-004) с Idempotency-Key, превью цены и скидки лояльности, успех записи (BS-002).
- `FL-09/10/11`: мои записи (SCR-005), детали брони (SCR-006) с оценкой маршала, отмена (BS-003) с правилом 2 часов.
- `FL-12`: карта трассы (BS-004) — geometry + текстовый fallback + внешняя карта.
- `FL-13`: профиль (SCR-007) — имя, лояльность, смена телефона OTP, logout, удаление аккаунта.
- `FL-14`: заглушка push-сервиса; плагин push не выбран. `GET /notifications` — backlog.
- `FL-15`: unit-тесты policies и репозиториев (`flutter test`).

Dev OTP-код бэкенда (fixtures): `0000`.
