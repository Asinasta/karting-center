# Apex Client API (backend)

Клиентский REST-API-слой картинг-центра «Апекс» для мобильного приложения.
Реализован на **Python + FastAPI** строго по OpenAPI-контракту из `01-analysis/api`.

Для MVP работает поверх **in-memory fixtures adapter** — внешняя инфраструктура не нужна.

## Требования

- Python 3.11+
- pip

## Установка

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1        # Windows PowerShell
# source .venv/bin/activate         # macOS/Linux
pip install -r requirements.txt
copy .env.example .env              # cp .env.example .env на macOS/Linux
```

## Переменные окружения (`.env`)

| Переменная | По умолчанию | Назначение |
|---|---|---|
| `APP_ENV` | `dev` | Окружение. В не-dev запрещены dev JWT-секреты. |
| `HTTP_ADDR` | `:8080` | Адрес/порт HTTP-сервера. |
| `JWT_ACCESS_SECRET` | `dev-access-secret` | Секрет для access-токена (15 мин). |
| `JWT_REFRESH_SECRET` | `dev-refresh-secret` | Секрет для refresh-токена (30 дней). |
| `BACKEND_ADAPTER` | `fixtures` | `fixtures` (dev/test) или `existing` (интеграция, пока не реализована). |

## Команды

```powershell
python manage.py run              # запуск API (uvicorn) на HTTP_ADDR
python manage.py test             # pytest
python manage.py lint             # ruff check
python manage.py format           # ruff format
python manage.py contract-check   # сверка операций OpenAPI с роутами
```

- Swagger UI: `http://localhost:8080/docs`
- Healthcheck (вне OpenAPI): `GET http://localhost:8080/healthz`

## Fixtures mode

При `BACKEND_ADAPTER=fixtures` и `APP_ENV=dev`:

- OTP-код всегда `0000` (dev-байпас).
- Засеян тестовый клиент с телефоном `+79990000000` и набором заездов/броней:
  доступный, заполненный, отменённый центром, без прокатной экипировки,
  а также активная / завершённая / отменённая центром брони.

## Smoke flow (PowerShell)

Полный сценарий: публичный каталог → auth gate → бронь → мои записи → профиль → отмена.

```powershell
$base = "http://localhost:8080"

# 1. Публичный каталог (без токена)
Invoke-RestMethod "$base/slots"
$slot = (Invoke-RestMethod "$base/slots?only_available=true")[0]

# 2. Send OTP + 3. Verify OTP (dev-код 0000)
Invoke-RestMethod -Method Post "$base/auth/otp" -ContentType application/json `
  -Body '{"phone":"+79991234567"}'
$tokens = Invoke-RestMethod -Method Post "$base/auth/verify" -ContentType application/json `
  -Body '{"phone":"+79991234567","code":"0000","name":"Тест"}'
$h = @{ Authorization = "Bearer $($tokens.access_token)" }

# 4. Create booking (нужен Idempotency-Key)
$hb = $h + @{ "Idempotency-Key" = [guid]::NewGuid().ToString() }
$booking = Invoke-RestMethod -Method Post "$base/bookings" -Headers $hb `
  -ContentType application/json `
  -Body (@{ slot_id = $slot.id; seat_gear = @("own","rental") } | ConvertTo-Json)

# 5. Мои записи + профиль
Invoke-RestMethod "$base/bookings" -Headers $h
Invoke-RestMethod "$base/profile" -Headers $h

# 6. Cancel booking
Invoke-RestMethod -Method Post "$base/bookings/$($booking.id)/cancel" -Headers $h
```

## Архитектура

```
app/
  contracts/     Pydantic DTO по OpenAPI (auth, slots, marshals, bookings, profile, common)
  domain/        Чистые сущности и политики (availability, cancellation, price), clock
  ports.py       Абстрактные порты между хендлерами и адаптерами
  adapters/      fixtures (in-memory, thread-safe) и existing (stub интеграции)
  routers/       HTTP-эндпоинты; имена функций = operationId
  security.py    JWT access/refresh
  errors.py      ApiError + реестр кодов ошибок контракта
  main.py        Фабрика app, middleware, обработчики ошибок, /healthz
  contract_check.py  Сверка OpenAPI ↔ роуты
manage.py        run / test / lint / format / contract-check
```

## Известные решения и допущения

- Ошибки валидации запроса (тело/query/заголовки/невалидный JSON) возвращаются как
  `validation_error` со статусом **400** (единый формат `{code, message, details}`).
  Доменные ошибки (`slot_full`, `slot_cancelled`, `slot_started`, `double_booking`,
  `already_cancelled`, `phone_already_used`, …) используют статусы из контракта.
- `Idempotency-Key` с изменённым payload → `validation_error` (422).
- Поздняя отмена (`< 2h`) не освобождает места и фиксируется как событие для
  существующей инфраструктуры (в fixtures — список `late_cancel` событий).
- `existing` adapter пока бросает `NotImplementedError`: используйте `fixtures`.
