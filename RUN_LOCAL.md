# Локальный запуск

## 1. Backend

Терминал №1:

```bash
cd backend
.\.venv\Scripts\python.exe manage.py run
```

Проверка:

```text
http://localhost:8080/healthz
http://localhost:8080/docs
http://localhost:8080/slots
```

## 2. Flutter web

Терминал №2:

```bash
cd client
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

Открой вручную:

```text
http://127.0.0.1:3000
```

## Альтернатива: Chrome debug

```bash
cd client
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

На некоторых машинах Chrome debug mode может зависать на `Waiting for connection from debug service on Chrome...`.

## После изменения зависимостей

**Клиент** (`client/pubspec.yaml`):

```bash
cd client && flutter pub get
```

**Backend** (`backend/requirements.txt`):

```bash
cd backend && pip install -r requirements.txt
```

## Правило запуска

Сначала backend, потом Flutter-клиент.

## Dev-учётка (fixtures)

При `APP_ENV=dev` и `BACKEND_ADAPTER=fixtures` (см. `backend/.env.example`):

- **Телефон:** `+79990000000` — засеянный тестовый клиент с историей броней
- **OTP:** `0000` — для этого номера и для любого другого `+7...` в dev-режиме

## Smoke-сценарий

Список заездов → фильтры → карточка → «Записаться» → OTP (`+79990000000` или любой `+7...`, код **0000**) → бронь → успех → «Мои записи» → детали → оценка маршала (после старта) → отмена → профиль (лояльность) → выход.

Автопроверки:

```bash
cd backend && python manage.py test
cd client && flutter analyze && flutter test
```
