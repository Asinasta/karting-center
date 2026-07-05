# Скачать и запустить проект локально

Репозиторий: https://github.com/asinasta/karting-center

## Что нужно установить

| Инструмент | Версия | Зачем |
|---|---|---|
| Git | любая свежая | скачать проект |
| Python | 3.11+ | backend API |
| Flutter | stable | клиентское приложение |

Проверка:

```powershell
git --version
python --version
flutter --version
```

Flutter: https://docs.flutter.dev/get-started/install

---

## 1. Скачать проект

### Вариант A — через Git (рекомендуется)

```powershell
cd C:\Users\%USERNAME%\Downloads
git clone https://github.com/asinasta/karting-center.git
cd karting-center
```

### Вариант B — ZIP с GitHub

1. Открой https://github.com/asinasta/karting-center
2. **Code → Download ZIP**
3. Распакуй архив, например в `C:\Users\%USERNAME%\Downloads\karting-center`
4. Открой PowerShell в этой папке

---

## 2. Первичная настройка backend (один раз)

Открой **PowerShell №1**:

```powershell
cd C:\Users\%USERNAME%\Downloads\karting-center\backend

python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env
```

Проверка:

```powershell
.\.venv\Scripts\python.exe manage.py test
```

Должно пройти без ошибок (около 69 тестов).

---

## 3. Первичная настройка клиента (один раз)

Открой **PowerShell №2**:

```powershell
cd C:\Users\%USERNAME%\Downloads\karting-center\client
flutter pub get
flutter analyze
flutter test
```

---

## 4. Запуск

**Сначала backend, потом клиент.**

### PowerShell №1 — backend

```powershell
cd C:\Users\%USERNAME%\Downloads\karting-center\backend
.\.venv\Scripts\python.exe manage.py run
```

Проверка в браузере:

```text
http://localhost:8080/healthz
http://localhost:8080/docs
http://localhost:8080/slots
```

### PowerShell №2 — Flutter web

```powershell
cd C:\Users\%USERNAME%\Downloads\karting-center\client
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

Открой в браузере:

```text
http://127.0.0.1:3000
```

### Альтернатива: Chrome debug

```powershell
cd C:\Users\%USERNAME%\Downloads\karting-center\client
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

На некоторых машинах Chrome debug может зависать на
`Waiting for connection from debug service on Chrome...` — тогда используй `web-server` выше.

---

## 5. Вход в приложение (dev-режим)

Backend работает на **fixtures** — тестовые данные в памяти.

| Параметр | Значение |
|---|---|
| OTP-код | `0000` |
| Тестовый телефон | `+79990000000` |
| Любой новый телефон | тоже работает с кодом `0000` |

Smoke-сценарий:

1. Открой список заездов (без входа).
2. Нажми «Записаться» → введи телефон и код `0000`.
3. Оформи бронь → «Мои записи» → отмена → «Профиль».

---

## Обновление после `git pull`

```powershell
cd C:\Users\%USERNAME%\Downloads\karting-center

# backend — только если менялся backend/requirements.txt
cd backend
.\.venv\Scripts\python.exe -m pip install -r requirements.txt

# client — только если менялся client/pubspec.yaml
cd ..\client
flutter pub get
```

---

## macOS / Linux

```bash
# Скачать
git clone https://github.com/asinasta/karting-center.git
cd karting-center

# Backend
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python manage.py run          # терминал 1

# Client (другой терминал)
cd ../client
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

---

## Частые проблемы

| Проблема | Решение |
|---|---|
| `Activate.ps1` не выполняется | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| Клиент не видит API | Сначала запусти backend, проверь `http://localhost:8080/healthz` |
| `flutter: command not found` | Добавь Flutter в PATH или перезапусти терминал после установки |
| Порт 8080 занят | Измени `HTTP_ADDR=:8081` в `backend/.env` и передай тот же URL в `--dart-define=API_BASE_URL=...` |
