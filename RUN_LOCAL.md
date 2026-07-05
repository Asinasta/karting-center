# Локальный запуск

## 1. Backend

Открой PowerShell №1:

```powershell
cd C:\Users\Asinasta\Downloads\karting-center\backend
.\.venv\Scripts\python.exe manage.py run
```

Проверка:

```text
http://localhost:8080/healthz
http://localhost:8080/docs
http://localhost:8080/slots
```

## 2. Flutter web

Открой PowerShell №2:

```powershell
cd C:\Users\Asinasta\Downloads\karting-center\client
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

Потом вручную открой:

```text
http://127.0.0.1:3000
```

## Альтернатива: Chrome debug

Можно пробовать так, но на этой машине Chrome debug mode может зависать на
`Waiting for connection from debug service on Chrome...`.

```powershell
cd C:\Users\Asinasta\Downloads\karting-center\client
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

## После изменения зависимостей клиента

Только если менялся `client/pubspec.yaml`:

```powershell
cd C:\Users\Asinasta\Downloads\karting-center\client
flutter pub get
```

## После изменения зависимостей backend

Только если менялся `backend/requirements.txt`:

```powershell
cd C:\Users\Asinasta\Downloads\karting-center\backend
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

## Правило запуска

Сначала запускай backend, потом Flutter-клиент.
