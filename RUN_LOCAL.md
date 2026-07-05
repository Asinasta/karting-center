# Локальный запуск

Замени `C:\Users\azari\karting-center` на свой путь к репозиторию.

## 1. Backend

Открой PowerShell №1:

```powershell
cd C:\Users\azari\karting-center\backend
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
cd C:\Users\azari\karting-center\client
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

Потом вручную открой:

```text
http://127.0.0.1:3000
```

## Альтернатива: Chrome debug

Можно пробовать так, но на некоторых машинах Chrome debug mode зависает на
`Waiting for connection from debug service on Chrome...`.

```powershell
cd C:\Users\azari\karting-center\client
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://localhost:8080
```

## После `git pull` (если Flutter «сломался»)

Выполни из папки `client/`:

```powershell
cd C:\Users\azari\karting-center\client
.\check.ps1
```

Или вручную:

```powershell
cd C:\Users\azari\karting-center\client
flutter --version          # нужен Dart 3.9+ (Flutter 3.32+)
flutter pub get
flutter clean
flutter pub get
flutter analyze
flutter test
```

Убедись, что на `main` последний коммит (сейчас `f622164` — фикс web-старта).

```powershell
cd C:\Users\azari\karting-center
git log -1 --oneline
```

### Частые проблемы

| Симптом | Что делать |
| --- | --- |
| `flutter` не найден | Переоткрой PowerShell; проверь `where.exe flutter` |
| `version solving failed` / Dart too old | `flutter upgrade` (нужен Dart **3.9+**) |
| Белый экран в браузере | Сначала запусти backend; обнови `main` до `f622164+` |
| `pub get` / странные ошибки сборки | `flutter clean`, затем снова `flutter pub get` |
| Запуск из корня репозитория | Команды `flutter` — только из папки **`client/`** |

## После изменения зависимостей клиента

Только если менялся `client/pubspec.yaml`:

```powershell
cd C:\Users\azari\karting-center\client
flutter pub get
```

## После изменения зависимостей backend

Только если менялся `backend/requirements.txt`:

```powershell
cd C:\Users\azari\karting-center\backend
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

## Правило запуска

Сначала запускай backend, потом Flutter-клиент.
